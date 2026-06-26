# frozen_string_literal: true

module Api
  module V1
    module Platform
      class AdminsController < BaseController
        before_action :require_super_admin!, only: [ :password ]
        before_action :set_admin, only: [ :password ]

        def index
          admins = PlatformAdminUser.order(:email)
          render_success(admins.map { |admin| admin_payload(admin) })
        end

        def password
          new_password = params[:new_password]
          confirm_password = params[:confirm_password]

          if new_password.blank? || confirm_password.blank?
            return render_error("New password and confirmation are required", :bad_request)
          end

          if new_password != confirm_password
            return render_error("New password and confirmation do not match", :bad_request)
          end

          if new_password.length < 8
            return render_error("Password must be at least 8 characters long", :bad_request)
          end

          if @admin.update(password: new_password, password_confirmation: confirm_password)
            render_success({ message: "Password updated for #{@admin.email}" })
          else
            render_error(@admin.errors.full_messages.join(", "))
          end
        end

        private

        def require_super_admin!
          return if current_platform_admin&.role == "super_admin"

          render_error("Only super admins can manage platform admin passwords", :forbidden)
        end

        def set_admin
          @admin = PlatformAdminUser.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Platform admin not found", :not_found)
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
