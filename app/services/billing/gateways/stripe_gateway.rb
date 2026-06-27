# frozen_string_literal: true

require "stripe"

module Billing
  module Gateways
    class StripeGateway < Base
      CURRENCY = "inr"

      def gateway_name
        "stripe"
      end

      def configured?
        api_key.present?
      end

      def ensure_customer!(company, email:)
        assert_configured!
        return company.gateway_customer_id if company.gateway_customer_id.present?

        customer = Stripe::Customer.create(
          email: email.presence || company.contact_email,
          name: company.name,
          metadata: { company_id: company.id, company_code: company.code }
        )
        company.update!(payment_gateway: gateway_name, gateway_customer_id: customer.id)
        customer.id
      end

      def create_checkout_session(company:, plan:, billing_cycle:, seats:, success_url:, cancel_url:)
        assert_configured!
        customer_id = ensure_customer!(company, email: company.contact_email)
        price_id = ensure_price!(plan, billing_cycle)

        session = Stripe::Checkout::Session.create(
          customer: customer_id,
          mode: "subscription",
          line_items: [ { price: price_id, quantity: seats } ],
          success_url: success_url,
          cancel_url: cancel_url,
          subscription_data: {
            metadata: {
              company_id: company.id,
              plan: plan.slug,
              billing_cycle: billing_cycle
            }
          },
          metadata: {
            company_id: company.id,
            plan: plan.slug,
            billing_cycle: billing_cycle,
            seats: seats
          }
        )

        { url: session.url, session_id: session.id }
      end

      def change_plan(company:, new_plan:, billing_cycle:, seats:)
        assert_configured!
        raise PaymentError, "No active subscription to change" if company.gateway_subscription_id.blank?

        subscription = Stripe::Subscription.retrieve(company.gateway_subscription_id)
        new_price_id = ensure_price!(new_plan, billing_cycle)
        item_id = subscription.items.data.first&.id

        updated = Stripe::Subscription.update(
          company.gateway_subscription_id,
          items: [
            { id: item_id, deleted: true },
            { price: new_price_id, quantity: seats }
          ],
          proration_behavior: "create_prorations",
          metadata: {
            company_id: company.id,
            plan: new_plan.slug,
            billing_cycle: billing_cycle
          }
        )

        company.update!(
          plan: new_plan.slug,
          billing_cycle: billing_cycle,
          billable_seats: seats,
          max_employees: new_plan.max_employees
        )

        {
          subscription_id: updated.id,
          status: updated.status,
          proration_applied: true
        }
      end

      def cancel_subscription(company)
        assert_configured!
        return unless company.gateway_subscription_id.present?

        Stripe::Subscription.cancel(company.gateway_subscription_id, prorate: true)
        company.update!(gateway_subscription_id: nil)
      end

      def billing_portal_url(company:, return_url:)
        assert_configured!
        raise PaymentError, "No billing customer on file" if company.gateway_customer_id.blank?

        session = Stripe::BillingPortal::Session.create(
          customer: company.gateway_customer_id,
          return_url: return_url
        )
        { url: session.url }
      end

      def sync_subscription(company)
        assert_configured!
        return unless company.gateway_subscription_id.present?

        subscription = Stripe::Subscription.retrieve(company.gateway_subscription_id)
        apply_subscription_state!(company, subscription)
      end

      def handle_webhook(payload:, signature:)
        assert_configured!
        secret = webhook_secret
        raise ConfigurationError, "STRIPE_WEBHOOK_SECRET is not configured" if secret.blank?

        event = Stripe::Webhook.construct_event(payload, signature, secret)
        Billing::WebhookProcessor.new(gateway: self).process(event)
        { received: true, type: event.type }
      rescue Stripe::SignatureVerificationError
        raise PaymentError, "Invalid webhook signature"
      end

      def apply_checkout_completed!(session)
        company = Company.find(session.metadata["company_id"])
        subscription_id = session.subscription
        subscription = Stripe::Subscription.retrieve(subscription_id)

        company.update!(
          gateway_subscription_id: subscription_id,
          payment_gateway: gateway_name,
          plan: session.metadata["plan"],
          billing_cycle: session.metadata["billing_cycle"],
          billable_seats: session.metadata["seats"].to_i,
          status: "active"
        )
        apply_subscription_state!(company, subscription)
        company
      end

      def apply_invoice_paid!(stripe_invoice)
        company = find_company_by_customer(stripe_invoice.customer)
        return unless company

        PlatformInvoice.find_or_initialize_by(gateway_invoice_id: stripe_invoice.id).tap do |inv|
          inv.company = company
          inv.amount = (stripe_invoice.amount_paid / 100.0).round
          inv.status = "paid"
          inv.paid_at = Time.at(stripe_invoice.status_transitions.paid_at) if stripe_invoice.status_transitions&.paid_at
          inv.plan = company.plan
          inv.payment_gateway = gateway_name
          inv.receipt_url = stripe_invoice.hosted_invoice_url
          inv.billing_period_start = stripe_invoice.lines&.data&.first&.period&.start ? Time.at(stripe_invoice.lines.data.first.period.start).to_date : nil
          inv.billing_period_end = stripe_invoice.lines&.data&.first&.period&.end ? Time.at(stripe_invoice.lines.data.first.period.end).to_date : nil
          inv.save!
        end

        company.activate_subscription!(plan: company.plan, billing_cycle: company.billing_cycle) if company.status != "active"
      end

      def apply_subscription_updated!(subscription)
        company = find_company_by_customer(subscription.customer)
        return unless company

        company.update!(gateway_subscription_id: subscription.id)
        apply_subscription_state!(company, subscription)
      end

      def apply_subscription_deleted!(subscription)
        company = find_company_by_customer(subscription.customer)
        return unless company

        company.update!(gateway_subscription_id: nil, status: "past_due") if company.status == "active"
      end

      private

      def api_key
        ENV["STRIPE_SECRET_KEY"].presence
      end

      def webhook_secret
        ENV["STRIPE_WEBHOOK_SECRET"].presence
      end

      def assert_configured!
        Stripe.api_key = api_key
        raise ConfigurationError, "STRIPE_SECRET_KEY is not configured" unless configured?
      end

      def ensure_price!(plan, billing_cycle)
        column = billing_cycle == "annual" ? :gateway_price_annual_id : :gateway_price_monthly_id
        return plan.public_send(column) if plan.public_send(column).present?

        product_id = ensure_product!(plan)
        interval = billing_cycle == "annual" ? "year" : "month"
        unit_amount = billing_cycle == "annual" ? annual_per_seat_amount(plan) : per_seat_amount(plan)

        price = Stripe::Price.create(
          product: product_id,
          unit_amount: unit_amount * 100,
          currency: CURRENCY,
          recurring: { interval: interval, usage_type: "licensed" },
          metadata: { plan_slug: plan.slug, billing_cycle: billing_cycle }
        )

        plan.update!(column => price.id)
        price.id
      end

      def ensure_product!(plan)
        return plan.gateway_product_id if plan.gateway_product_id.present?

        product = Stripe::Product.create(
          name: "BevyHR #{plan.name}",
          description: plan.description,
          metadata: { plan_slug: plan.slug }
        )
        plan.update!(gateway_product_id: product.id)
        product.id
      end

      def annual_per_seat_amount(plan)
        return (plan.per_seat_price * 12 * 0.85).ceil if plan.per_seat_price.to_i.positive? && plan.annual_price.to_i.zero?

        per_seat = per_seat_amount(plan)
        (per_seat * 12 * 0.85).ceil
      end

      def apply_subscription_state!(company, subscription)
        period_end = subscription.current_period_end
        company.update!(
          renews_at: Time.at(period_end),
          status: subscription.status.in?(%w[active trialing]) ? "active" : "past_due"
        )
      end

      def find_company_by_customer(customer_id)
        Company.find_by(gateway_customer_id: customer_id)
      end
    end
  end
end
