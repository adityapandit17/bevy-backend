class Message < ApplicationRecord
  include BelongsToTenant

  belongs_to :channel
  belongs_to :user

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_channel, ->(channel_id) { where(channel_id: channel_id) }

  # Broadcast message after creation
  after_create_commit :broadcast_message

  # Mark message as edited
  def mark_as_edited!
    update!(edited_at: Time.current)
  end

  def edited?
    edited_at.present?
  end

  private

  def assign_company_from_current
    self.company_id ||= channel&.company_id || Current.company&.id
  end

  def broadcast_message
    # Ensure user association is loaded
    user_record = user

    ActionCable.server.broadcast(
      "chat_channel_#{channel_id}",
      {
        type: "message",
        message: {
          id: id,
          channel_id: channel_id,
          user_id: user_id,
          user_name: user_record.name || user_record.email&.split("@")&.first || "Unknown User",
          user_email: user_record.email || "",
          content: content,
          edited_at: edited_at&.iso8601,
          created_at: created_at.iso8601,
          updated_at: updated_at.iso8601
        }
      }
    )

    # Also notify all channel members about the update
    channel.users.each do |member|
      ActionCable.server.broadcast(
        "user_#{member.id}_channels",
        {
          type: "channel_updated",
          channel_id: channel_id
        }
      )
    end
  end
end
