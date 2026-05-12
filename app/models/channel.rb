class Channel < ApplicationRecord
  include BelongsToTenant

  belongs_to :created_by, class_name: "User"
  has_many :channel_memberships, dependent: :destroy
  has_many :users, through: :channel_memberships
  has_many :messages, dependent: :destroy
  has_many :huddles, dependent: :destroy

  validates :name, presence: true
  validates :channel_type, presence: true, inclusion: { in: %w[channel direct group] }
  validates :is_private, inclusion: { in: [ true, false ] }

  scope :public_channels, -> { where(is_private: false, channel_type: "channel") }
  scope :private_channels, -> { where(is_private: true, channel_type: "channel") }
  scope :direct_messages, -> { where(channel_type: "direct") }
  scope :groups, -> { where(channel_type: "group") }

  # Get unread count for a specific user
  def unread_count_for(user)
    membership = channel_memberships.find_by(user: user)
    return 0 unless membership

    last_read = membership.last_read_at || Time.at(0)
    messages.where("created_at > ?", last_read).count
  end

  # Get last message
  def last_message
    messages.order(created_at: :desc).first
  end

  # Check if user is a member
  def member?(user)
    channel_memberships.exists?(user: user)
  end

  # Get display name for direct messages
  def display_name_for(user)
    return name if channel_type != "direct"

    other_user = users.where.not(id: user.id).first
    other_user&.name || name
  end
end
