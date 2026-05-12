require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @channel = channels(:one)
    @message = Message.new(
      channel: @channel,
      user: @user,
      content: "Hello, team!"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @message.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require content" do
    @message.content = nil
    assert_not @message.valid?
    assert_includes @message.errors[:content], "can't be blank"
  end

  test "should require channel" do
    @message.channel = nil
    assert_not @message.valid?
  end

  test "should require user" do
    @message.user = nil
    assert_not @message.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to channel" do
    assert_respond_to @message, :channel
  end

  test "should belong to user" do
    assert_respond_to @message, :user
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "recent scope orders by created_at descending" do
    @message.save!
    newer = Message.create!(channel: @channel, user: @user, content: "Second message")
    assert_equal newer, Message.recent.first
  end

  test "for_channel scope filters by channel_id" do
    @message.save!
    other_channel = channels(:two)
    other_message = Message.create!(channel: other_channel, user: users(:two), content: "Other")
    assert_includes Message.for_channel(@channel.id), @message
    assert_not_includes Message.for_channel(@channel.id), other_message
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "edited? returns false when edited_at is nil" do
    @message.edited_at = nil
    assert_not @message.edited?
  end

  test "edited? returns true when edited_at is set" do
    @message.edited_at = Time.current
    assert @message.edited?
  end

  test "mark_as_edited! sets edited_at" do
    @message.save!
    @message.mark_as_edited!
    assert_not_nil @message.reload.edited_at
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create message" do
    assert_difference("Message.count") { @message.save! }
  end

  test "should update message content" do
    @message.save!
    @message.update!(content: "Updated message")
    assert_equal "Updated message", @message.reload.content
  end

  test "should destroy message" do
    @message.save!
    assert_difference("Message.count", -1) { @message.destroy }
  end
end
