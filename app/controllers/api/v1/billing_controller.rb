# frozen_string_literal: true

module Api
  module V1
    class BillingController < ApplicationController
      before_action :authenticate_user!
      skip_around_action :with_tenant_from_user, raise: false
      around_action :with_tenant_for_billing

      def summary
        company = current_user.company
        plans = PricingPlan.published.ordered.map(&:platform_json)
        invoices = company.platform_invoices.recent.limit(20).map(&:tenant_json)

        render_success({
          company: billing_company_payload(company),
          plans: plans,
          invoices: invoices,
          gateway: billing_gateway_payload,
          billable_seats: company.billable_seat_count,
          can_checkout: company.status.in?(%w[trial past_due pending]) || company.subscription_locked?,
          can_change_plan: company.gateway_subscription_id.present? && company.status == "active"
        })
      end

      def checkout
        company = current_user.company
        plan = params.require(:plan)
        billing_cycle = params[:billing_cycle].presence || "monthly"

        manager = Billing::SubscriptionManager.new
        frontend = ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
        result = manager.checkout(
          company: company,
          plan: plan,
          billing_cycle: billing_cycle,
          success_url: "#{frontend}/settings?tab=billing&checkout=success",
          cancel_url: "#{frontend}/settings?tab=billing&checkout=cancelled",
          seats: params[:seats]
        )

        render_success(result)
      rescue Billing::GatewayError => e
        render_error(e.message)
      end

      def change_plan
        company = current_user.company
        manager = Billing::SubscriptionManager.new
        result = manager.change_plan(
          company: company,
          new_plan: params.require(:plan),
          billing_cycle: params[:billing_cycle],
          seats: params[:seats]
        )

        render_success(result.merge(company: billing_company_payload(company.reload)))
      rescue Billing::GatewayError => e
        render_error(e.message)
      end

      def portal
        company = current_user.company
        frontend = ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
        result = Billing::SubscriptionManager.new.portal_url(
          company: company,
          return_url: "#{frontend}/settings?tab=billing"
        )
        render_success(result)
      rescue Billing::GatewayError => e
        render_error(e.message)
      end

      def invoices
        company = current_user.company
        render_success(company.platform_invoices.recent.map(&:tenant_json))
      end

      private

      def with_tenant_for_billing
        company = current_user&.company
        if company.blank?
          render json: { success: false, error: "User is not associated with a company" }, status: :forbidden
          return
        end

        ActsAsTenant.with_tenant(company) do
          yield
        end
      end

      def billing_company_payload(company)
        company.settings_json.merge(
          billable_seats: company.billable_seat_count,
          has_payment_method: company.gateway_customer_id.present?,
          gateway_subscription_id: company.gateway_subscription_id
        )
      end

      def billing_gateway_payload
        gateway = Billing::GatewayFactory.build
        {
          name: gateway.gateway_name,
          configured: gateway.configured?,
          publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"].presence
        }
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
