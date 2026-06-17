class PasswordResetMailer < ApplicationMailer
  default from: "noreply@bevyhr.com"

  def reset_password_email(user, reset_password_token)
    @user = user
    @reset_password_token = reset_password_token
    @asset_base_url = Rails.application.config.action_mailer.asset_host || mailer_base_url
    @reset_url = frontend_reset_password_url(reset_password_token)

    mail(
      to: @user.email,
      subject: "Reset your BevyHR password"
    )
  end
end
