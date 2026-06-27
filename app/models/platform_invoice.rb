# frozen_string_literal: true

class PlatformInvoice < ApplicationRecord
  STATUSES = %w[draft sent paid overdue cancelled].freeze

  belongs_to :company

  validates :invoice_number, :amount, presence: true
  validates :invoice_number, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :generate_invoice_number, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def platform_json
    as_json.merge(
      "company_name" => company.name,
      "company_id" => company_id,
      "created_at" => created_at
    )
  end

  def tenant_json
    {
      id: id,
      invoice_number: invoice_number,
      amount: amount,
      status: status,
      plan: plan,
      due_date: due_date,
      paid_at: paid_at,
      receipt_url: receipt_url,
      billing_period_start: billing_period_start,
      billing_period_end: billing_period_end,
      created_at: created_at
    }
  end

  private

  def generate_invoice_number
    return if invoice_number.present?

    prefix = "INV-#{Time.current.strftime('%Y%m')}"
    last = PlatformInvoice.where("invoice_number LIKE ?", "#{prefix}-%").order(:invoice_number).last
    seq = last ? last.invoice_number.split("-").last.to_i + 1 : 1
    self.invoice_number = format("%s-%04d", prefix, seq)
  end
end
