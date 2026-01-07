class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to all channels the user is a member of
    current_user.channels.each do |channel|
      stream_from "chat_channel_#{channel.id}"
    end

    # Also subscribe to user-specific updates
    stream_from "user_#{current_user.id}_channels"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    # Handle incoming messages if needed
    # This can be used for typing indicators, etc.
  end
end
