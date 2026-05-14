class WelcomeMailer < ApplicationMailer
  default from: "noreply@bevyhr.com"

  def welcome_email(employee, invitation_token)
    @employee = employee
    @invitation_token = invitation_token
    @asset_base_url = Rails.application.config.action_mailer.asset_host || mailer_base_url
    @invitation_url = frontend_invitation_accept_url(invitation_token)

    mail(
      to: @employee.email,
      subject: "Welcome to BevyHR - Complete Your Account Setup"
    )
  end

  def invitation_email(user, invitation_token)
    @user = user
    @invitation_token = invitation_token
    @asset_base_url = Rails.application.config.action_mailer.asset_host || mailer_base_url
    @invitation_url = frontend_invitation_accept_url(invitation_token)

    mail(
      to: @user.email,
      subject: "You've been invited to join BevyHR"
    )
  end
end
