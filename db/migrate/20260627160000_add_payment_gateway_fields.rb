# frozen_string_literal: true

class AddPaymentGatewayFields < ActiveRecord::Migration[8.1]
  def change
    change_table :companies, bulk: true do |t|
      t.string :payment_gateway, default: "stripe", null: false
      t.string :gateway_customer_id
      t.string :gateway_subscription_id
      t.integer :billable_seats, default: 1, null: false
    end
    add_index :companies, :gateway_customer_id
    add_index :companies, :gateway_subscription_id

    change_table :pricing_plans, bulk: true do |t|
      t.string :gateway_product_id
      t.string :gateway_price_monthly_id
      t.string :gateway_price_annual_id
      t.integer :per_seat_price, default: 0, null: false
    end

    change_table :platform_invoices, bulk: true do |t|
      t.string :gateway_invoice_id
      t.string :receipt_url
      t.string :payment_gateway
    end
    add_index :platform_invoices, :gateway_invoice_id
  end
end
