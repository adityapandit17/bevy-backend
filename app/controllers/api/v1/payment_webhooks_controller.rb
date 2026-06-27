# frozen_string_literal: true

module Api
  module V1
    class PaymentWebhooksController < ApplicationController
      skip_before_action :authenticate_user_from_token!, raise: false
      skip_around_action :with_tenant_from_user, raise: false

      def stripe
        gateway = Billing::GatewayFactory.build("stripe")
        result = gateway.handle_webhook(
          payload: request.body.read,
          signature: request.headers["Stripe-Signature"]
        )
        render json: { success: true, data: result }
      rescue Billing::PaymentError => e
        render json: { success: false, error: e.message }, status: :bad_request
      rescue Billing::GatewayError => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
