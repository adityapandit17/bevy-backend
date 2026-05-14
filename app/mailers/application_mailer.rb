class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_DEFAULT_FROM", "BevyHR <no-reply@bevyhr.com>")
  layout "mailer"

  private

  def mailer_base_url
    opts = Rails.application.config.action_mailer.default_url_options || {}
    host = opts[:host] || "localhost:3000"
    protocol = opts[:protocol] || "http"
    "#{protocol}://#{host}"
  end

  # Next.js (or any SPA) route that collects password and calls POST /api/v1/auth/accept_invitation.
  def frontend_invitation_accept_url(invitation_token)
    base = ENV.fetch("FRONTEND_URL", "http://localhost:3001").to_s.chomp("/")
    encoded = URI.encode_www_form_component(invitation_token.to_s)
    "#{base}/accept-invitation?invitation_token=#{encoded}"
  end
end
