# frozen_string_literal: true

module Api
  module V1
    module Platform
      class SubscriptionRequestsController < BaseController
        before_action :require_billing_or_super!, except: [ :index, :show ]
        before_action :set_request, only: [ :show, :approve, :reject ]

        def index
          requests = SubscriptionRequest.includes(:company).recent
          requests = requests.where(status: params[:status]) if params[:status].present?
          render_success(requests.map(&:platform_json))
        end

        def show
          render_success(@request.platform_json)
        end

        def create
          request_record = SubscriptionRequest.new(subscription_request_params)
          if request_record.save
            render_success(request_record.platform_json, :created)
          else
            render_error(request_record.errors.full_messages.join(", "))
          end
        end

        def approve
          company = SubscriptionRequestApprovalService.new(@request, approver: current_platform_admin).approve!
          audit_action!(action: "subscription_request.approve", company: company, resource: @request, metadata: { request_type: @request.request_type, plan: @request.plan })
          render_success({ request: @request.reload.platform_json, company: company.platform_json })
        rescue SubscriptionRequestApprovalService::ApprovalError => e
          render_error(e.message)
        end

        def reject
          SubscriptionRequestApprovalService.new(@request).reject!(notes: params[:notes])
          audit_action!(action: "subscription_request.reject", company: @request.company, resource: @request, metadata: { notes: params[:notes] })
          render_success(@request.reload.platform_json)
        rescue SubscriptionRequestApprovalService::ApprovalError => e
          render_error(e.message)
        end

        private

        def set_request
          @request = SubscriptionRequest.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Subscription request not found", :not_found)
        end

        def subscription_request_params
          params.require(:subscription_request).permit(
            :company_id, :company_name, :request_type, :plan, :seats, :amount,
            :billing_cycle, :status, :requested_by, :notes
          )
        end
      end
    end
  end
end
