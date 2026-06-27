# frozen_string_literal: true

module Api
  module V1
    module Platform
      class SettingsController < BaseController
        before_action :require_super_admin!, only: [ :update ]

        def show
          render_success(PlatformSetting.settings_json)
        end

        def update
          PlatformSetting.update_settings!(settings_params)
          audit_action!(action: "settings.update", metadata: { settings: settings_params })
          render_success(PlatformSetting.settings_json)
        end

        private

        def settings_params
          params.require(:settings).permit(
            :product_name, :marketing_url, :tenant_app_url,
            :maintenance_mode, :allow_signups, :require_email_verification, :default_trial_days
          ).to_h.transform_values(&:to_s)
        end
      end
    end
  end
end
