# frozen_string_literal: true

module Billing
  class WebhookProcessor
    HANDLED_EVENTS = %w[
      checkout.session.completed
      invoice.paid
      invoice.payment_failed
      customer.subscription.updated
      customer.subscription.deleted
    ].freeze

    def initialize(gateway: GatewayFactory.build)
      @gateway = gateway
    end

    def process(event)
      return unless HANDLED_EVENTS.include?(event.type)
      return unless gateway.is_a?(Gateways::StripeGateway)

      case event.type
      when "checkout.session.completed"
        gateway.apply_checkout_completed!(event.data.object)
      when "invoice.paid"
        gateway.apply_invoice_paid!(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      when "customer.subscription.updated"
        gateway.apply_subscription_updated!(event.data.object)
      when "customer.subscription.deleted"
        gateway.apply_subscription_deleted!(event.data.object)
      end
    end

    private

    attr_reader :gateway

    def handle_payment_failed(stripe_invoice)
      company = Company.find_by(gateway_customer_id: stripe_invoice.customer)
      return unless company

      company.update!(status: "past_due")
      PlatformInvoice.find_or_initialize_by(gateway_invoice_id: stripe_invoice.id).tap do |inv|
        inv.company = company
        inv.amount = (stripe_invoice.amount_due / 100.0).round
        inv.status = "overdue"
        inv.plan = company.plan
        inv.payment_gateway = "stripe"
        inv.due_date = Date.current
        inv.save!
      end
    end
  end
end
