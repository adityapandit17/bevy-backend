# frozen_string_literal: true

module Api
  module V1
    module Platform
      class AuditsController < BaseController
        before_action :require_super_admin!, only: [ :index ]

        def index
          logs = PlatformAuditLog.includes(:platform_admin_user, :company).recent
          logs = logs.where(platform_admin_user_id: params[:admin_id]) if params[:admin_id].present?
          logs = logs.where(company_id: params[:company_id]) if params[:company_id].present?
          logs = logs.where(action: params[:action]) if params[:action].present?
          logs = logs.global_only if params[:scope] == "global"

          limit = params[:limit].to_i
          limit = 50 if limit <= 0
          limit = [ limit, 100 ].min
          offset = [ params[:offset].to_i, 0 ].max

          total = logs.count
          entries = logs.offset(offset).limit(limit)

          render_success({
            total: total,
            limit: limit,
            offset: offset,
            entries: entries.map(&:platform_json)
          })
        end
      end
    end
  end
end
