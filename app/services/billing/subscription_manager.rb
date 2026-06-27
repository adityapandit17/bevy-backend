# frozen_string_literal: true

module Billing
  class SubscriptionManager
    def initialize(gateway: GatewayFactory.build)
      @gateway = gateway
    end

    def checkout(company:, plan:, billing_cycle:, success_url:, cancel_url:, seats: nil)
      pricing = PricingPlan.find_by!(slug: plan.to_s)
      seat_count = seats || gateway.send(:billable_seats_for, company, plan: pricing)

      gateway.ensure_customer!(company, email: company.contact_email)
      gateway.create_checkout_session(
        company: company,
        plan: pricing,
        billing_cycle: billing_cycle,
        seats: seat_count,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    def change_plan(company:, new_plan:, billing_cycle: nil, seats: nil)
      pricing = PricingPlan.find_by!(slug: new_plan.to_s)
      cycle = billing_cycle.presence || company.billing_cycle
      seat_count = seats || gateway.send(:billable_seats_for, company, plan: pricing)

      gateway.change_plan(
        company: company,
        new_plan: pricing,
        billing_cycle: cycle,
        seats: seat_count
      )
    end

    def portal_url(company:, return_url:)
      gateway.ensure_customer!(company, email: company.contact_email)
      gateway.billing_portal_url(company: company, return_url: return_url)
    end

    def cancel(company)
      gateway.cancel_subscription(company)
    end

    def sync(company)
      gateway.sync_subscription(company)
    end

    private

    attr_reader :gateway
  end
end
