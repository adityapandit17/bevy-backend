class ChatChannel < ApplicationCable::Channel
  def subscribed
    unless current_user
      reject
      return
    end

    # Subscribe to all channels the user is a member of
    channels = current_user.channels
    Rails.logger.info "ChatChannel subscribed for user #{current_user.id}, subscribing to #{channels.count} channels"
    
    channels.each do |channel|
      stream_from "chat_channel_#{channel.id}"
      Rails.logger.info "Subscribed to chat_channel_#{channel.id}"
    end

    # Also subscribe to user-specific updates
    stream_from "user_#{current_user.id}_channels"
    Rails.logger.info "Subscribed to user_#{current_user.id}_channels"
  end

  def unsubscribed
    Rails.logger.info "ChatChannel unsubscribed for user #{current_user&.id}"
  end

  def receive(data)
    # Handle incoming messages if needed
    # This can be used for typing indicators, etc.
  end
end
