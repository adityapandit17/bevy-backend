# frozen_string_literal: true

module Api
  module V1
    module Platform
      class AuthController < ApplicationController
        skip_before_action :authenticate_user_from_token!
        before_action :authenticate_platform_admin!, only: [ :logout, :me ]

        def login
          email = params[:email]&.downcase&.strip
          password = params[:password]

          if email.blank? || password.blank?
            return render json: { success: false, error: "Email and password are required" }, status: :bad_request
          end

          admin = PlatformAdminUser.find_by(email: email)

          if admin&.valid_password?(password) && admin.active?
            token = PlatformJwtService.generate_token(admin)
            render json: {
              success: true,
              data: {
                token: token,
                admin: admin_payload(admin)
              }
            }
          else
            render json: { success: false, error: "Invalid email or password" }, status: :unauthorized
          end
        end

        def logout
          render json: { success: true, data: { message: "Logged out successfully" } }
        end

        def me
          render json: { success: true, data: { admin: admin_payload(current_platform_admin) } }
        end

        private

        def authenticate_platform_admin!
          token = JwtService.extract_token(request.headers["Authorization"])
          @current_platform_admin = PlatformJwtService.verify_token(token)

          unless @current_platform_admin
            render json: { success: false, error: "Authentication required" }, status: :unauthorized
          end
        end

        def current_platform_admin
          @current_platform_admin
        end

        def admin_payload(admin)
          {
            id: admin.id,
            email: admin.email,
            name: admin.name,
            first_name: admin.first_name,
            last_name: admin.last_name,
            role: admin.role,
            status: admin.status,
            last_login_at: admin.last_login_at
          }
        end
      end
    end
  end
end
