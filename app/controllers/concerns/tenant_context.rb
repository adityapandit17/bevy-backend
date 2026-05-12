# frozen_string_literal: true

# Sets Current.company from X-Company-Id header or the user's default membership.
# Skipped for auth/login and super_admin JSON routes that manage tenants globally.
module TenantContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tenant, if: :should_set_current_tenant?
    after_action :clear_current_tenant
  end

  private

  def should_set_current_tenant?
    return false unless json_request?
    return false unless @current_user.present?
    return false if skip_tenant_context?

    true
  end

  def skip_tenant_context?
    path = request.path
    return true if path == "/api/v1/auth/login"
    # Allow loading user + workspace list before a company header is chosen
    return true if path == "/api/v1/auth/me"
    return true if path == "/api/v1/auth/refresh"
    return true if path.start_with?("/super_admin/")

    false
  end

  def set_current_tenant
    header = request.headers["X-Company-Id"].to_s.strip
    code_header = request.headers["X-Company-Code"].to_s.strip
    company = nil

    if header.present? && header.to_i.positive?
      company = Company.find_by(id: header.to_i)
      unless company
        return render json: { success: false, error: "Unknown workspace" }, status: :unprocessable_entity
      end
      unless @current_user.can_access_company?(company)
        return render json: { success: false, error: "Access denied for this workspace" }, status: :forbidden
      end
    elsif code_header.present?
      normalized = code_header.downcase
      company = Company.where("LOWER(code) = ?", normalized).first
      unless company
        return render json: { success: false, error: "Unknown workspace" }, status: :unprocessable_entity
      end
      unless @current_user.can_access_company?(company)
        return render json: { success: false, error: "Access denied for this workspace" }, status: :forbidden
      end
    else
      company = @current_user.default_company_for_session
      unless company
        return render json: {
          success: false,
          error: "No workspace available. Send X-Company-Id or assign the user to a company."
        }, status: :unprocessable_entity
      end
    end

    Current.company = company
    Current.user = @current_user
  end

  def clear_current_tenant
    Current.reset
  end
end
