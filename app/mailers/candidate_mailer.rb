class CandidateMailer < ApplicationMailer
  default from: "from@example.com"

  def candidate_email(candidate, subject, message, sender_name = nil)
    @candidate = candidate
    @subject = subject
    @message = message
    @sender_name = sender_name || "HR Team"
    @host = Rails.application.config.action_mailer.default_url_options[:host] || "localhost:3000"

    mail(
      to: @candidate.email,
      subject: @subject
    )
  end
end
