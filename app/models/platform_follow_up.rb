# frozen_string_literal: true

class PlatformFollowUp < ApplicationRecord
  STATUSES = %w[scheduled completed overdue].freeze
  TYPES = %w[call email demo].freeze

  belongs_to :platform_inquiry

  validates :company_name, :assignee, :due_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :follow_up_type, inclusion: { in: TYPES }

  before_validation :sync_status_from_due_date, on: :create

  scope :overdue, -> { where(status: "overdue").or(where(status: "scheduled").where("due_date < ?", Date.current)) }
  scope :due_soon, -> { order(:due_date) }

  def platform_json
    as_json.merge(
      "inquiry_id" => platform_inquiry_id,
      "created_at" => created_at
    )
  end

  private

  def sync_status_from_due_date
    return if status == "completed"
    self.status = "overdue" if due_date.present? && due_date < Date.current
  end
end
