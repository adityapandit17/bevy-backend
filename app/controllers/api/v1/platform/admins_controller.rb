# frozen_string_literal: true

module Api
  module V1
    module Platform
      class AdminsController < BaseController
        before_action :require_super_admin!, except: [ :index ]
        before_action :set_admin, only: [ :password, :update, :destroy ]

        def index
          admins = PlatformAdminUser.order(:email)
          render_success(admins.map { |admin| admin_payload(admin) })
        end

        def create
          role = sanitize_admin_role(params.dig(:admin, :role))
          return render_error("Invalid or missing admin role", :bad_request) if role.blank?

          status = sanitize_admin_status(params.dig(:admin, :status)) || "active"
          return render_error("Invalid admin status", :bad_request) if params.dig(:admin, :status).present? && status.blank?

          admin = PlatformAdminUser.new(admin_profile_params)
          admin.email = params.require(:admin)[:email]
          admin.role = role
          admin.status = status
          admin.password = params[:password]
          admin.password_confirmation = params[:password_confirmation] || params[:password]

          if admin.save
            audit_action!(action: "admin.create", resource: admin, metadata: { email: admin.email, role: admin.role })
            render_success(admin_payload(admin), :created)
          else
            render_error(admin.errors.full_messages.join(", "))
          end
        end

        def update
          attrs = admin_profile_params.to_h

          if params.dig(:admin, :role).present?
            role = sanitize_admin_role(params.dig(:admin, :role))
            return render_error("Invalid admin role", :bad_request) if role.blank?

            attrs[:role] = role
          end

          if params.dig(:admin, :status).present?
            status = sanitize_admin_status(params.dig(:admin, :status))
            return render_error("Invalid admin status", :bad_request) if status.blank?

            attrs[:status] = status
          end

          if @admin.update(attrs)
            audit_record_update!(action: "admin.update", record: @admin)
            render_success(admin_payload(@admin))
          else
            render_error(@admin.errors.full_messages.join(", "))
          end
        end

        def destroy
          if @admin.id == current_platform_admin.id
            return render_error("You cannot deactivate your own account")
          end

          @admin.update!(status: "inactive")
          audit_action!(action: "admin.deactivate", resource: @admin, metadata: { email: @admin.email })
          render_success({ message: "Admin deactivated" })
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
            audit_action!(action: "admin.password_reset", resource: @admin, metadata: { email: @admin.email })
            render_success({ message: "Password updated for #{@admin.email}" })
          else
            render_error(@admin.errors.full_messages.join(", "))
          end
        end

        private

        def set_admin
          @admin = PlatformAdminUser.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Platform admin not found", :not_found)
        end

        def admin_profile_params
          params.require(:admin).permit(:first_name, :last_name)
        end

        def sanitize_admin_role(value)
          role = value.to_s
          PlatformAdminUser::ROLES.include?(role) ? role : nil
        end

        def sanitize_admin_status(value)
          status = value.to_s
          PlatformAdminUser::STATUSES.include?(status) ? status : nil
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
