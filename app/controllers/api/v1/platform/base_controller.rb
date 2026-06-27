# frozen_string_literal: true

module Api
  module V1
    module Platform
      class BaseController < ApplicationController
        include PlatformAuditable

        skip_before_action :authenticate_user_from_token!
        skip_around_action :with_tenant_from_user, raise: false

        before_action :authenticate_platform_admin!

        private

        def authenticate_platform_admin!
          token = JwtService.extract_token(request.headers["Authorization"])

          if token.blank?
            return render json: { success: false, error: "Authorization token is required" }, status: :unauthorized
          end

          @current_platform_admin = PlatformJwtService.verify_token(token)

          unless @current_platform_admin
            render json: { success: false, error: "Invalid or expired token" }, status: :unauthorized
          end
        end

        def current_platform_admin
          @current_platform_admin
        end

        def render_success(data, status = :ok)
          render json: { success: true, data: data }, status: status
        end

        def render_error(message, status = :unprocessable_entity, code: nil)
          payload = { success: false, error: message }
          payload[:code] = code if code.present?
          render json: payload, status: status
        end

        def require_super_admin!
          return if current_platform_admin&.role == "super_admin"

          render_error("Only super admins can perform this action", :forbidden)
        end

        def require_billing_or_super!
          return if current_platform_admin&.role.in?(%w[super_admin billing])

          render_error("Insufficient permissions", :forbidden)
        end
      end
    end
  end
end
