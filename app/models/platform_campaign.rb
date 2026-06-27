# frozen_string_literal: true

class PlatformCampaign < ApplicationRecord
  CHANNELS = %w[email linkedin webinar ads].freeze
  STATUSES = %w[draft active paused ended].freeze

  validates :name, presence: true
  validates :channel, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def platform_json
    as_json.merge(
      "sent" => sent_count,
      "start_date" => start_date&.iso8601,
      "end_date" => end_date&.iso8601,
      "created_at" => created_at
    )
  end
end
