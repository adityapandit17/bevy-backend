class CallChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to user-specific call channel
    user_id = params[:user_id]
    return reject unless user_id

    # Verify user is authenticated
    unless current_user
      reject
      return
    end

    # Verify user_id matches current_user (users can only subscribe to their own channel)
    unless user_id.to_i == current_user.id
      reject
      return
    end

    # Subscribe to user's call channel for receiving calls
    stream_from "user_#{current_user.id}_calls"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Handle WebRTC signaling messages
  def receive(data)
    case data["type"]
    when "call-offer"
      handle_call_offer(data)
    when "call-answer"
      handle_call_answer(data)
    when "call-reject"
      handle_call_reject(data)
    when "call-end"
      handle_call_end(data)
    when "ice-candidate"
      handle_ice_candidate(data)
    end
  end

  private

  def handle_call_offer(data)
    from_user_id = data["from"]["id"]
    to_user_id = data["to"]["id"]
    call_id = data["callId"]

    Rails.logger.info "Call offer received: from_user_id=#{from_user_id}, to_user_id=#{to_user_id}, call_id=#{call_id}, current_user_id=#{current_user.id}"

    # Verify the call is from the current user
    unless from_user_id == current_user.id
      Rails.logger.warn "Call offer rejected: from_user_id (#{from_user_id}) != current_user.id (#{current_user.id})"
      return
    end

    # Broadcast call offer to the recipient ONLY (not back to sender)
    Rails.logger.info "Broadcasting call offer to user_#{to_user_id}_calls (recipient)"
    ActionCable.server.broadcast(
      "user_#{to_user_id}_calls",
      {
        type: "call-offer",
        callId: call_id,
        from: data["from"],
        to: data["to"],
        offer: data["offer"]
      }
    )
    
    Rails.logger.info "Call offer broadcasted successfully to recipient"
  end

  def handle_call_answer(data)
    call_id = data["callId"]
    from_user_id = data["from"]&.dig("id")
    to_user_id = data["to"]&.dig("id")

    Rails.logger.info "Call answer received: call_id=#{call_id}, from_user_id=#{from_user_id}, to_user_id=#{to_user_id}, current_user_id=#{current_user.id}"

    # Verify the answer is from the current user (the recipient)
    unless from_user_id == current_user.id
      Rails.logger.warn "Call answer rejected: from_user_id (#{from_user_id}) != current_user.id (#{current_user.id})"
      return
    end

    # Broadcast answer to the caller (to_user_id is the caller)
    if to_user_id
      Rails.logger.info "Broadcasting call answer to user_#{to_user_id}_calls"
      ActionCable.server.broadcast(
        "user_#{to_user_id}_calls",
        {
          type: "call-answer",
          callId: call_id,
          answer: data["answer"]
        }
      )
      Rails.logger.info "Call answer broadcasted successfully"
    end
  end

  def handle_call_reject(data)
    call_id = data["callId"]
    
    # Broadcast rejection to all participants
    # In a real implementation, you'd track call participants
    ActionCable.server.broadcast(
      "call_#{call_id}",
      {
        type: "call-reject",
        callId: call_id
      }
    )
  end

  def handle_call_end(data)
    call_id = data["callId"]
    from_user_id = data["from"]&.dig("id") || current_user.id
    to_user_id = data["to"]&.dig("id")
    
    Rails.logger.info "Call end received: call_id=#{call_id}, from_user_id=#{from_user_id}, to_user_id=#{to_user_id}, current_user_id=#{current_user.id}"
    
    # Broadcast call end to the other participant
    if to_user_id && to_user_id != current_user.id
      Rails.logger.info "Broadcasting call end to user_#{to_user_id}_calls"
      ActionCable.server.broadcast(
        "user_#{to_user_id}_calls",
        {
          type: "call-end",
          callId: call_id,
          from: data["from"],
          to: data["to"]
        }
      )
      Rails.logger.info "Call end broadcasted successfully"
    end
    
    # Also broadcast to the sender's channel (in case they need it)
    if from_user_id == current_user.id && to_user_id
      ActionCable.server.broadcast(
        "user_#{from_user_id}_calls",
        {
          type: "call-end",
          callId: call_id,
          from: data["from"],
          to: data["to"]
        }
      )
    end
  end

  def handle_ice_candidate(data)
    call_id = data["callId"]
    candidate = data["candidate"]
    from_user_id = data["from"]&.dig("id") || current_user.id
    to_user_id = data["to"]&.dig("id")
    
    Rails.logger.info "ICE candidate received: call_id=#{call_id}, from_user_id=#{from_user_id}, to_user_id=#{to_user_id}, current_user_id=#{current_user.id}"
    
    # Verify the ICE candidate is from the current user
    unless from_user_id == current_user.id
      Rails.logger.warn "ICE candidate rejected: from_user_id (#{from_user_id}) != current_user.id (#{current_user.id})"
      return
    end
    
    # Broadcast ICE candidate to the other participant (to_user_id)
    if to_user_id
      Rails.logger.info "Broadcasting ICE candidate to user_#{to_user_id}_calls"
      ActionCable.server.broadcast(
        "user_#{to_user_id}_calls",
        {
          type: "ice-candidate",
          callId: call_id,
          candidate: candidate
        }
      )
      Rails.logger.info "ICE candidate broadcasted successfully"
    else
      Rails.logger.warn "No to_user_id provided for ICE candidate"
    end
  end
end
