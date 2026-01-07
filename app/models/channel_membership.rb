class ChannelMembership < ApplicationRecord
  belongs_to :channel
  belongs_to :user

  validates :role, presence: true, inclusion: { in: %w[admin member] }
  validates :user_id, uniqueness: { scope: :channel_id, message: "is already a member of this channel" }

  scope :admins, -> { where(role: "admin") }
  scope :members, -> { where(role: "member") }

  # Update last read timestamp
  def mark_as_read!
    update!(last_read_at: Time.current)
  end
end
