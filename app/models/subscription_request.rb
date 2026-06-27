# frozen_string_literal: true

class SubscriptionRequest < ApplicationRecord
  REQUEST_TYPES = %w[new_tenant upgrade renewal seat_add].freeze
  STATUSES = %w[pending approved rejected].freeze
  BILLING_CYCLES = %w[monthly annual].freeze

  belongs_to :company, optional: true

  validates :request_type, inclusion: { in: REQUEST_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :billing_cycle, inclusion: { in: BILLING_CYCLES }
  validates :plan, inclusion: { in: Company::PLANS }

  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def platform_json
    as_json.merge(
      "company" => company&.name || company_name,
      "company_id" => company_id,
      "requested_at" => created_at
    )
  end
end
