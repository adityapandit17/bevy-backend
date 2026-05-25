# frozen_string_literal: true

module Api
  module V1
    class GoogleCalendarController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, except: [ :callback ]
      before_action :authorize_settings_index!, only: [ :status ]
      before_action :authorize_settings_update!, only: [ :authorize_url, :disconnect ]

      # GET /api/v1/google_calendar/status
      def status
        company = current_company
        render_success(GoogleCalendarOauthService.status_for(company))
      end

      # GET /api/v1/google_calendar/authorize_url
      def authorize_url
        unless GoogleCalendarOauthService.oauth_configured?
          return render_error("Google Calendar OAuth is not configured on the server", :service_unavailable)
        end

        url = GoogleCalendarOauthService.authorization_url(current_user)
        render_success({ authorization_url: url })
      rescue GoogleCalendarOauthService::Error => e
        render_error(e.message, :unprocessable_entity)
      end

      # GET /api/v1/google_calendar/callback — Google redirects here (no JWT)
      def callback
        result = GoogleCalendarOauthService.handle_callback(params[:code], params[:state])
        redirect_to integrations_settings_url("connected", email: result[:email]), allow_other_host: true
      rescue GoogleCalendarOauthService::Error => e
        redirect_to integrations_settings_url("error", message: e.message), allow_other_host: true
      rescue StandardError => e
        Rails.logger.error "[GoogleCalendar] callback failed: #{e.message}"
        redirect_to integrations_settings_url("error", message: "Failed to connect Google Calendar"), allow_other_host: true
      end

      # DELETE /api/v1/google_calendar/disconnect
      def disconnect
        if GoogleCalendarService.platform_mode_active?
          return render_error(
            "Calendar is configured via server environment (platform account). Remove GOOGLE_CALENDAR_ENABLED and GOOGLE_CALENDAR_REFRESH_TOKEN from server config to disconnect.",
            :unprocessable_entity
          )
        end

        company = current_company
        GoogleCalendarOauthService.disconnect!(company)
        render_success(GoogleCalendarOauthService.status_for(company.reload))
      rescue GoogleCalendarOauthService::Error => e
        render_error(e.message, :unprocessable_entity)
      end

      private

      def current_company
        Company.first || Company.create!(
          name: "Default Company",
          code: "DEF",
          industry: "General",
          employee_count: "0",
          timezone: "UTC",
          currency: "USD"
        )
      end

      def integrations_settings_url(result, email: nil, message: nil)
        base = ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
        query = { tab: "integrations", google_calendar: result }
        query[:email] = email if email.present?
        query[:message] = message if message.present?
        "#{base}/settings?#{query.to_query}"
      end

      def authorize_settings_index!
        authorize!("settings", "index")
      end

      def authorize_settings_update!
        authorize!("settings", "update")
      end

      def render_success(data, status = :ok)
        render json: { success: true, data: data }, status: status
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { success: false, error: message }, status: status
      end
    end
  end
end
