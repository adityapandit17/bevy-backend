# frozen_string_literal: true

module Api
  module V1
    module Platform
      class FollowUpsController < BaseController
        before_action :set_follow_up, only: [ :show, :update, :destroy ]

        def index
          follow_ups = PlatformFollowUp.includes(:platform_inquiry).due_soon
          follow_ups = follow_ups.where(status: params[:status]) if params[:status].present?
          render_success(follow_ups.map(&:platform_json))
        end

        def show
          render_success(@follow_up.platform_json)
        end

        def create
          follow_up = PlatformFollowUp.new(follow_up_params)
          if follow_up.save
            audit_action!(action: "follow_up.create", resource: follow_up, metadata: { company_name: follow_up.company_name })
            render_success(follow_up.platform_json, :created)
          else
            render_error(follow_up.errors.full_messages.join(", "))
          end
        end

        def update
          if @follow_up.update(follow_up_params)
            audit_record_update!(action: "follow_up.update", record: @follow_up)
            render_success(@follow_up.platform_json)
          else
            render_error(@follow_up.errors.full_messages.join(", "))
          end
        end

        def destroy
          company_name = @follow_up.company_name
          @follow_up.destroy!
          audit_action!(action: "follow_up.destroy", metadata: { company_name: company_name })
          render_success({ message: "Follow-up deleted" })
        end

        private

        def set_follow_up
          @follow_up = PlatformFollowUp.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Follow-up not found", :not_found)
        end

        def follow_up_params
          params.require(:follow_up).permit(
            :platform_inquiry_id, :company_name, :assignee, :due_date,
            :status, :follow_up_type, :notes
          )
        end
      end
    end
  end
end
