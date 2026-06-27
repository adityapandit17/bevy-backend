# frozen_string_literal: true

module Api
  module V1
    module Platform
      class InquiriesController < BaseController
        before_action :set_inquiry, only: [ :show, :update, :destroy ]

        def index
          inquiries = PlatformInquiry.recent
          inquiries = inquiries.where(status: params[:status]) if params[:status].present?
          render_success(inquiries.map(&:platform_json))
        end

        def show
          render_success(@inquiry.platform_json)
        end

        def create
          inquiry = PlatformInquiry.new(inquiry_params)
          if inquiry.save
            audit_action!(action: "inquiry.create", resource: inquiry, metadata: { company_name: inquiry.company_name, email: inquiry.email })
            render_success(inquiry.platform_json, :created)
          else
            render_error(inquiry.errors.full_messages.join(", "))
          end
        end

        def update
          if @inquiry.update(inquiry_params)
            audit_record_update!(action: "inquiry.update", record: @inquiry)
            render_success(@inquiry.platform_json)
          else
            render_error(@inquiry.errors.full_messages.join(", "))
          end
        end

        def destroy
          name = @inquiry.company_name
          @inquiry.destroy!
          audit_action!(action: "inquiry.destroy", metadata: { company_name: name })
          render_success({ message: "Inquiry deleted" })
        end

        private

        def set_inquiry
          @inquiry = PlatformInquiry.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Inquiry not found", :not_found)
        end

        def inquiry_params
          params.require(:inquiry).permit(
            :company_name, :contact_name, :email, :source, :plan_interest,
            :estimated_seats, :assignee, :status, :notes
          )
        end
      end
    end
  end
end
