class Huddle < ApplicationRecord
  belongs_to :channel
  belongs_to :started_by, class_name: "User"
  has_many :huddle_participants, dependent: :destroy
  has_many :participants, through: :huddle_participants, source: :user

  validates :status, presence: true, inclusion: { in: %w[active ended] }
  validates :started_at, presence: true

  scope :active, -> { where(status: "active") }
  scope :ended, -> { where(status: "ended") }
  scope :for_channel, ->(channel_id) { where(channel_id: channel_id) }

  def active?
    status == "active"
  end

  def end!
    update!(status: "ended", ended_at: Time.current)
    # Broadcast end event
    ActionCable.server.broadcast(
      "chat_channel_#{channel_id}",
      {
        type: "huddle_ended",
        huddle_id: id,
        channel_id: channel_id
      }
    )
    
    # Also notify via user channels
    channel.users.each do |member|
      ActionCable.server.broadcast(
        "user_#{member.id}_channels",
        {
          type: "huddle_ended",
          huddle_id: id,
          channel_id: channel_id
        }
      )
    end
  end

  def add_participant(user)
    huddle_participants.find_or_create_by(user: user) do |participant|
      participant.joined_at = Time.current
    end
  end

  def remove_participant(user)
    participant = huddle_participants.find_by(user: user)
    return unless participant

    participant.update!(left_at: Time.current)
    
    # If no active participants, end the huddle
    if huddle_participants.where(left_at: nil).count.zero?
      end!
    end
  end

  def active_participants
    huddle_participants.where(left_at: nil).includes(:user)
  end
end
