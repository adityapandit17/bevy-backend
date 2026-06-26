require "test_helper"

class CallChannelTest < ActionCable::Channel::TestCase
  tests CallChannel

  setup do
    @caller = users(:admin)
    @callee = users(:one)
    stub_connection current_user: @caller
  end

  test "subscribes when user_id matches current user" do
    subscribe user_id: @caller.id
    assert subscription.confirmed?
    assert_has_stream "user_#{@caller.id}_calls"
  end

  test "rejects subscription when user_id does not match current user" do
    subscribe user_id: @callee.id
    assert subscription.rejected?
  end

  test "relays call-offer to recipient stream with media type" do
    subscribe user_id: @caller.id

    offer = { type: "offer", sdp: "v=0" }
    perform :receive, {
      type: "call-offer",
      callId: "call_test_1",
      from: { id: @caller.id, name: @caller.name, email: @caller.email },
      to: { id: @callee.id, name: @callee.name, email: @callee.email },
      offer: offer,
      mediaType: "video"
    }

    assert_broadcast_on("user_#{@callee.id}_calls") do |payload|
      payload["type"] == "call-offer" &&
        payload["callId"] == "call_test_1" &&
        payload["mediaType"] == "video" &&
        payload["offer"] == offer
    end
  end

  test "does not relay call-offer when sender is not current user" do
    subscribe user_id: @caller.id

    assert_no_broadcasts do
      perform :receive, {
        type: "call-offer",
        callId: "call_test_2",
        from: { id: @callee.id, name: @callee.name, email: @callee.email },
        to: { id: @caller.id, name: @caller.name, email: @caller.email },
        offer: { type: "offer", sdp: "v=0" }
      }
    end
  end

  test "relays call-answer to caller" do
    subscribe user_id: @callee.id

    answer = { type: "answer", sdp: "v=0" }
    perform :receive, {
      type: "call-answer",
      callId: "call_test_3",
      from: { id: @callee.id, name: @callee.name, email: @callee.email },
      to: { id: @caller.id, name: @caller.name, email: @caller.email },
      answer: answer
    }

    assert_broadcast_on("user_#{@caller.id}_calls") do |payload|
      payload["type"] == "call-answer" && payload["answer"] == answer
    end
  end

  test "relays ice-candidate to other participant" do
    subscribe user_id: @caller.id

    candidate = { candidate: "candidate:1", sdpMid: "0", sdpMLineIndex: 0 }
    perform :receive, {
      type: "ice-candidate",
      callId: "call_test_4",
      from: { id: @caller.id },
      to: { id: @callee.id },
      candidate: candidate
    }

    assert_broadcast_on("user_#{@callee.id}_calls") do |payload|
      payload["type"] == "ice-candidate" && payload["candidate"] == candidate
    end
  end
end
