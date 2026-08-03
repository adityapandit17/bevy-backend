ErrorTrack.configure do |config|
  # Turn capturing off entirely (e.g. in test env)
  # config.enabled = !Rails.env.test?

  # Exception classes to never record
  # config.ignored_exceptions += ["MyApp::ExpectedError"]

  # Resolve the current user for context on each occurrence.
  # Called with the ActionDispatch::Request.
  # config.current_user_resolver = ->(request) {
  #   user = request.env["warden"]&.user
  #   { id: user&.id, email: user&.email } if user
  # }

  # Days to retain resolved errors (informational; wire up your own
  # cleanup rake task/cron using this if desired)
  # config.retention_days = 30
end

# Restrict access to the /errors dashboard - IMPORTANT for anything
# beyond local development. Example using an admin auth method:
#
# Rails.application.config.to_prepare do
#   ErrorTrack::ErrorsController.class_eval do
#     before_action :authenticate_admin!
#   end
# end
#
# Or with HTTP basic auth:
#
# Rails.application.config.to_prepare do
#   ErrorTrack::ErrorsController.class_eval do
#     http_basic_authenticate_with name: Rails.application.credentials.dig(:error_track, :user),
#                                   password: Rails.application.credentials.dig(:error_track, :password)
#   end
# end
