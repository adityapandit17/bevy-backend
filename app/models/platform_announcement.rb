# frozen_string_literal: true

class PlatformAnnouncement < ApplicationRecord
  STATUSES = %w[draft active ended].freeze
  AUDIENCES = %w[all trial active admins].freeze

  belongs_to :platform_admin_user, optional: true

  validates :title, :message, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :audience, inclusion: { in: AUDIENCES }

  scope :active_now, -> {
    where(status: "active")
      .where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at >= ?", Time.current)
  }
  scope :recent, -> { order(created_at: :desc) }

  def platform_json
    as_json.merge(
      "created_by" => platform_admin_user&.name,
      "starts_at" => starts_at,
      "ends_at" => ends_at,
      "created_at" => created_at
    )
  end
end
