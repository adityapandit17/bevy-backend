# frozen_string_literal: true

module SetCurrentTenant
  extend ActiveSupport::Concern

  included do
    around_action :with_tenant_from_user, if: :should_set_tenant?
  end

  private

  def should_set_tenant?
    return false unless json_request? || bearer_authenticated_request?
    return false if platform_api_path?
    return false if authentication_exempt?
    return false unless @current_user.present?

    true
  end

  def bearer_authenticated_request?
    JwtService.extract_token(request.headers["Authorization"]).present?
  end

  def platform_api_path?
    request.path.start_with?("/api/v1/platform/")
  end

  def with_tenant_from_user
    company = @current_user.company

    if company.blank?
      render json: { success: false, error: "User is not associated with a company" }, status: :forbidden
      return
    end

    unless company.accessible?
      if platform_impersonating?
        ActsAsTenant.with_tenant(company) { yield }
        return
      end

      if subscription_exempt_path?
        yield
        return
      end

      code = company.trial_expired? ? "TRIAL_EXPIRED" : "SUBSCRIPTION_LOCKED"
      message = company.trial_expired? ? "Your trial has ended. Please subscribe to continue." : "Company account is not active"
      render json: { success: false, error: message, code: code }, status: :forbidden
      return
    end

    ActsAsTenant.with_tenant(company) do
      yield
    end
  end

  def subscription_exempt_path?
    request.path == "/api/v1/auth/me" ||
      request.path == "/api/v1/auth/logout" ||
      request.path == "/api/v1/auth/stop_impersonation" ||
      request.path.start_with?("/api/v1/billing/")
  end

  def platform_impersonating?
    JwtService.impersonating?(@jwt_payload) && @jwt_payload&.dig("platform_admin_id").present?
  end
end
