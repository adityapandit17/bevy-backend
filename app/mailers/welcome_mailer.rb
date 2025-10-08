class WelcomeMailer < ApplicationMailer
  default from: 'noreply@hrms.com'

  def welcome_email(employee, invitation_token)
    @employee = employee
    @invitation_token = invitation_token
    @invitation_url = Rails.application.routes.url_helpers.accept_user_invitation_url(
      invitation_token: invitation_token,
      host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
    )
    
    mail(
      to: @employee.email,
      subject: "Welcome to HRMS - Complete Your Account Setup"
    )
  end

  def invitation_email(user, invitation_token)
    @user = user
    @invitation_token = invitation_token
    @invitation_url = Rails.application.routes.url_helpers.accept_user_invitation_url(
      invitation_token: invitation_token,
      host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
    )
    
    mail(
      to: @user.email,
      subject: "You've been invited to join HRMS"
    )
  end
end
