# frozen_string_literal: true

module Billing
  class GatewayFactory
    REGISTRY = {
      "stripe" => "Billing::Gateways::StripeGateway"
    }.freeze

    def self.build(name = nil)
      key = (name || ENV.fetch("PAYMENT_GATEWAY", "stripe")).to_s.downcase
      class_name = REGISTRY[key]
      raise GatewayError, "Unknown payment gateway: #{key}" unless class_name

      class_name.constantize.new
    end

    def self.available
      REGISTRY.keys
    end
  end
end
