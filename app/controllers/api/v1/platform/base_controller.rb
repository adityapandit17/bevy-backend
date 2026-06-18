# frozen_string_literal: true

module Api
  module V1
    module Platform
      class BaseController < ApplicationController
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

        def render_error(message, status = :unprocessable_entity)
          render json: { success: false, error: message }, status: status
        end
      end
    end
  end
end
