# frozen_string_literal: true

require "signet/oauth_2/client"
require "net/http"
require "json"

# OAuth 2.0 connect/disconnect for company Google Calendar (Settings → Integrations).
class GoogleCalendarOauthService
  OAUTH_SCOPES = [
    Google::Apis::CalendarV3::AUTH_CALENDAR,
    "https://www.googleapis.com/auth/userinfo.email"
  ].freeze

  class Error < StandardError; end

  class << self
    def oauth_configured?
      ENV["GOOGLE_CALENDAR_CLIENT_ID"].present? &&
        ENV["GOOGLE_CALENDAR_CLIENT_SECRET"].present?
    end

    def redirect_uri
      ENV.fetch("GOOGLE_CALENDAR_REDIRECT_URI") do
        "#{app_base_url}/api/v1/google_calendar/callback"
      end
    end

    def authorization_url(user)
      raise Error, "Google OAuth is not configured" unless oauth_configured?

      state = encode_state(user_id: user.id)
      oauth_client(state: state).authorization_uri.to_s
    end

    def handle_callback(code, state)
      raise Error, "Authorization code missing" if code.blank?

      payload = decode_state(state)
      user = User.find_by(id: payload[:user_id])
      raise Error, "Invalid OAuth state" unless user
      raise Error, "Insufficient permissions" unless user.has_permission?("settings", "update")

      token_client = oauth_client(state: nil)
      token_client.code = code
      token_client.fetch_access_token!

      refresh_token = token_client.refresh_token
      raise Error, "Google did not return a refresh token. Revoke app access in Google Account settings and try again." if refresh_token.blank?

      email = fetch_google_email(token_client.access_token)
      company = user.company
      raise Error, "Company record not found" unless company

      company.update!(
        google_calendar_refresh_token: refresh_token,
        google_calendar_access_token: token_client.access_token,
        google_calendar_token_expires_at: token_expires_at(token_client),
        google_calendar_email: email,
        google_calendar_connected_at: Time.current,
        google_calendar_connected_by_user_id: user.id
      )

      { company: company, email: email }
    end

    def disconnect!(company)
      revoke_token(company.google_calendar_refresh_token) if company.google_calendar_refresh_token.present?

      company.update!(
        google_calendar_refresh_token: nil,
        google_calendar_access_token: nil,
        google_calendar_token_expires_at: nil,
        google_calendar_email: nil,
        google_calendar_connected_at: nil,
        google_calendar_connected_by_user_id: nil
      )
    end

    def status_for(company)
      mode = connection_mode_for(company)
      base = {
        oauth_configured: oauth_configured?,
        mode: mode,
        redirect_uri: oauth_configured? ? redirect_uri : nil,
        client_id_prefix: oauth_client_id_prefix
      }

      case mode
      when "platform"
        base.merge(
          connected: true,
          email: GoogleCalendarService.platform_email,
          connected_at: nil,
          platform_managed: true
        )
      when "company"
        base.merge(
          connected: true,
          email: company.google_calendar_email,
          connected_at: company.google_calendar_connected_at,
          platform_managed: false
        )
      else
        base.merge(
          connected: false,
          email: nil,
          connected_at: nil,
          platform_managed: false
        )
      end
    end

    private

    def connection_mode_for(company)
      return "platform" if GoogleCalendarService.platform_mode_active?
      return "company" if company.google_calendar_connected?

      "disconnected"
    end

    def oauth_client(state: nil)
      Signet::OAuth2::Client.new(
        client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
        authorization_uri: "https://accounts.google.com/o/oauth2/auth",
        token_credential_uri: "https://oauth2.googleapis.com/token",
        redirect_uri: redirect_uri,
        scope: OAUTH_SCOPES,
        access_type: "offline",
        prompt: "consent",
        state: state
      )
    end

    def encode_state(payload)
      Rails.application.message_verifier(:google_calendar_oauth).generate(payload, expires_in: 15.minutes)
    end

    def decode_state(state)
      raise Error, "Invalid OAuth state" if state.blank?

      payload = Rails.application.message_verifier(:google_calendar_oauth).verify(state)
      payload.symbolize_keys
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      raise Error, "OAuth state expired or invalid"
    end

    def fetch_google_email(access_token)
      uri = URI("https://www.googleapis.com/oauth2/v2/userinfo")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn "[GoogleCalendar] userinfo failed: #{response.code} #{response.body}"
        return nil
      end

      JSON.parse(response.body)["email"]
    end

    def revoke_token(token)
      uri = URI("https://oauth2.googleapis.com/revoke")
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(token: token)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    rescue StandardError => e
      Rails.logger.warn "[GoogleCalendar] token revoke failed: #{e.message}"
    end

    def token_expires_at(token_client)
      return nil unless token_client.expires_at

      Time.zone.at(token_client.expires_at)
    end

    def app_base_url
      ENV.fetch("APP_URL", "http://localhost:3000").chomp("/")
    end

    def oauth_client_id_prefix
      id = ENV["GOOGLE_CALENDAR_CLIENT_ID"].to_s
      return nil if id.blank?

      id.split("-").first
    end
  end
end
