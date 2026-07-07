class Message < ApplicationRecord
  include TenantScoped
  belongs_to :channel
  belongs_to :user

  validates :content, length: { maximum: 10_000 }, allow_blank: true
  validate :content_or_attachment_present

  scope :recent, -> { order(created_at: :desc) }
  scope :for_channel, ->(channel_id) { where(channel_id: channel_id) }

  def has_attachment?
    attachment_path.present?
  end

  def image_attachment?
    attachment_content_type&.start_with?("image/")
  end

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

  def content_or_attachment_present
    if content.blank? && attachment_path.blank?
      errors.add(:base, "Message must have text or an attachment")
    end
  end

  def broadcast_message
    user_record = user || User.find_by(id: user_id)

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
          attachment_path: attachment_path,
          attachment_filename: attachment_filename,
          attachment_content_type: attachment_content_type,
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
