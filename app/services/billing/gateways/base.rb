# frozen_string_literal: true

module Billing
  class GatewayError < StandardError; end
  class ConfigurationError < GatewayError; end
  class PaymentError < GatewayError; end

  # Open for extension (new gateways), closed for modification.
  # Subclasses implement gateway-specific API calls; callers use GatewayFactory only.
  module Gateways
    class Base
      def gateway_name
        raise NotImplementedError
      end

      def configured?
        raise NotImplementedError
      end

      def ensure_customer!(company, email:)
        raise NotImplementedError
      end

      def create_checkout_session(company:, plan:, billing_cycle:, seats:, success_url:, cancel_url:)
        raise NotImplementedError
      end

      def change_plan(company:, new_plan:, billing_cycle:, seats:)
        raise NotImplementedError
      end

      def cancel_subscription(company)
        raise NotImplementedError
      end

      def billing_portal_url(company:, return_url:)
        raise NotImplementedError
      end

      def sync_subscription(company)
        raise NotImplementedError
      end

      def handle_webhook(payload:, signature:)
        raise NotImplementedError
      end

      protected

      def pricing_plan_for(slug)
        PricingPlan.find_by!(slug: slug.to_s)
      end

      def billable_seats_for(company, plan:)
        seats = company.employee_count_number
        seats = 1 if seats < 1
        [ seats, plan.max_employees ].min
      end

      def per_seat_amount(plan)
        return plan.per_seat_price if plan.per_seat_price.to_i.positive?

        base = plan.monthly_price.to_i
        max = [ plan.max_employees, 1 ].max
        (base.to_f / max).ceil
      end
    end
  end
end
