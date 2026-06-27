# frozen_string_literal: true

module Api
  module V1
    module Platform
      class CampaignsController < BaseController
        before_action :set_campaign, only: [ :show, :update, :destroy ]

        def index
          render_success(PlatformCampaign.recent.map(&:platform_json))
        end

        def show
          render_success(@campaign.platform_json)
        end

        def create
          campaign = PlatformCampaign.new(campaign_params)
          if campaign.save
            audit_action!(action: "campaign.create", resource: campaign, metadata: { name: campaign.name })
            render_success(campaign.platform_json, :created)
          else
            render_error(campaign.errors.full_messages.join(", "))
          end
        end

        def update
          if @campaign.update(campaign_params)
            audit_record_update!(action: "campaign.update", record: @campaign)
            render_success(@campaign.platform_json)
          else
            render_error(@campaign.errors.full_messages.join(", "))
          end
        end

        def destroy
          name = @campaign.name
          @campaign.destroy!
          audit_action!(action: "campaign.destroy", metadata: { name: name })
          render_success({ message: "Campaign deleted" })
        end

        private

        def set_campaign
          @campaign = PlatformCampaign.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Campaign not found", :not_found)
        end

        def campaign_params
          params.require(:campaign).permit(
            :name, :channel, :audience, :status, :sent_count, :conversions,
            :budget, :start_date, :end_date
          )
        end
      end
    end
  end
end
