# frozen_string_literal: true

class PlatformInquiry < ApplicationRecord
  STATUSES = %w[new contacted qualified won lost].freeze

  has_many :platform_follow_ups, dependent: :destroy

  validates :company_name, :contact_name, :email, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :open, -> { where.not(status: %w[won lost]) }
  scope :recent, -> { order(created_at: :desc) }

  def platform_json
    as_json.merge(
      "created_at" => created_at,
      "follow_up_count" => platform_follow_ups.count
    )
  end
end
