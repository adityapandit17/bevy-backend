class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_DEFAULT_FROM", "BevyHR <no-reply@bevyhr.com>")
  layout "mailer"
end
