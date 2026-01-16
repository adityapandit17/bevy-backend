class HuddleChannel < ApplicationCable::Channel
  def subscribed
    huddle_id = params[:huddle_id]
    return reject unless huddle_id

    huddle = Huddle.find_by(id: huddle_id)
    return reject unless huddle

    # Check if user is a member of the channel
    unless huddle.channel.member?(current_user)
      reject
      return
    end

    stream_from "huddle_#{huddle_id}"
    
    # Broadcast that user joined the huddle signaling channel
    ActionCable.server.broadcast(
      "huddle_#{huddle_id}",
      {
        type: "signaling_ready",
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email
        }
      }
    )
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Handle WebRTC signaling messages
  def receive(data)
    huddle_id = params[:huddle_id]
    return unless huddle_id

    huddle = Huddle.find_by(id: huddle_id)
    return unless huddle&.active?

    # Check if user is a member of the channel
    unless huddle.channel.member?(current_user)
      return
    end

    # Broadcast signaling data to other participants (excluding sender)
    ActionCable.server.broadcast(
      "huddle_#{huddle_id}",
      {
        type: "webrtc_signal",
        from_user_id: current_user.id,
        signal_type: data["signal_type"], # offer, answer, ice-candidate
        signal_data: data["signal_data"],
        timestamp: Time.current.iso8601
      }
    )
  end
end
