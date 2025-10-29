class SendWelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(employee_id, invited_by_user_id)
    employee = Employee.find(employee_id)
    invited_by = User.find_by(id: invited_by_user_id)

    # Check if user already exists
    existing_user = User.find_by(email: employee.email)

    if existing_user
      Rails.logger.info "User already exists for employee #{employee.id}: #{employee.email}"
      return { success: false, message: "User already exists for this email" }

    end

    # Create user invitation with default role
    user = User.invite!(
      {
        email: employee.email,
        first_name: employee.first_name,
        last_name: employee.last_name,
        status: "active",
        employee_id: employee.id
      },
      invited_by
    ) do |u|
      u.skip_invitation = true
    end

    if user.persisted?
      # Assign default Employee role
      employee_role = Role.find_by(name: "Employee")
      if employee_role
        user.roles << employee_role
        employee.update(status: "active")
        Rails.logger.info "Assigned Employee role to user #{user.id}"
      else
        Rails.logger.warn "Employee role not found - user created without role"
      end

      # Send welcome email
      begin
        # WelcomeMailer.welcome_email(employee, user.invitation_token).deliver_now
        Rails.logger.info "Welcome email sent to #{employee.email}"

        {
          success: true,
          message: "Welcome email sent successfully",
          user_id: user.id,
          invitation_token: user.invitation_token
        }
      rescue => e
        Rails.logger.error "Failed to send welcome email: #{e.message}"
        {
          success: false,
          message: "User created but email failed to send: #{e.message}",
          user_id: user.id
        }
      end
    else
      Rails.logger.error "Failed to create user for employee #{employee.id}: #{user.errors.full_messages.join(', ')}"
      {
        success: false,
        message: "Failed to create user: #{user.errors.full_messages.join(', ')}"
      }
    end
  rescue => e
    Rails.logger.error "SendWelcomeEmailJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      message: "Job failed: #{e.message}"
    }
  end
end
