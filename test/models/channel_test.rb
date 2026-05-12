require "test_helper"

class ChannelTest < ActiveSupport::TestCase
  def setup
    @creator = users(:one)
    @channel = Channel.new(
      name: "project-alpha",
      channel_type: "channel",
      is_private: false,
      created_by: @creator,
      description: "Project Alpha discussion"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @channel.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require name" do
    @channel.name = nil
    assert_not @channel.valid?
    assert_includes @channel.errors[:name], "can't be blank"
  end

  test "should require channel_type" do
    @channel.channel_type = nil
    assert_not @channel.valid?
    assert_includes @channel.errors[:channel_type], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid channel_type" do
    @channel.channel_type = "broadcast"
    assert_not @channel.valid?
    assert_includes @channel.errors[:channel_type], "is not included in the list"
  end

  test "should accept all valid channel_types" do
    %w[channel direct group].each do |type|
      @channel.channel_type = type
      assert @channel.valid?, "#{type} should be valid"
    end
  end

  test "should require is_private to be boolean" do
    @channel.is_private = nil
    assert_not @channel.valid?
    assert_includes @channel.errors[:is_private], "is not included in the list"
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to created_by user" do
    assert_respond_to @channel, :created_by
  end

  test "should have many channel_memberships" do
    assert_respond_to @channel, :channel_memberships
  end

  test "should have many users through channel_memberships" do
    assert_respond_to @channel, :users
  end

  test "should have many messages" do
    assert_respond_to @channel, :messages
  end

  test "should have many huddles" do
    assert_respond_to @channel, :huddles
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "public_channels scope returns public channel-type channels" do
    @channel.is_private = false
    @channel.channel_type = "channel"
    @channel.save!
    private_channel = Channel.create!(
      name: "private-#{SecureRandom.hex(4)}",
      channel_type: "channel",
      is_private: true,
      created_by: @creator
    )
    assert_includes Channel.public_channels, @channel
    assert_not_includes Channel.public_channels, private_channel
  end

  test "private_channels scope returns private channel-type channels" do
    @channel.is_private = true
    @channel.save!
    assert_includes Channel.private_channels, @channel
  end

  test "direct_messages scope returns direct channels" do
    @channel.channel_type = "direct"
    @channel.save!
    assert_includes Channel.direct_messages, @channel
  end

  test "groups scope returns group channels" do
    @channel.channel_type = "group"
    @channel.save!
    assert_includes Channel.groups, @channel
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "member? returns true when user is a member" do
    @channel.save!
    ChannelMembership.create!(channel: @channel, user: @creator, role: "admin")
    assert @channel.member?(@creator)
  end

  test "member? returns false when user is not a member" do
    @channel.save!
    assert_not @channel.member?(users(:two))
  end

  test "last_message returns nil when no messages" do
    @channel.save!
    assert_nil @channel.last_message
  end

  test "last_message returns most recent message" do
    @channel.save!
    msg = Message.create!(channel: @channel, user: @creator, content: "Hello")
    assert_equal msg, @channel.last_message
  end

  test "unread_count_for returns 0 when user is not a member" do
    @channel.save!
    assert_equal 0, @channel.unread_count_for(@creator)
  end

  test "display_name_for returns channel name for non-direct channels" do
    assert_equal @channel.name, @channel.display_name_for(@creator)
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "destroying channel destroys dependent memberships" do
    @channel.save!
    ChannelMembership.create!(channel: @channel, user: @creator, role: "admin")
    assert_difference("ChannelMembership.count", -1) { @channel.destroy }
  end

  test "destroying channel destroys dependent messages" do
    @channel.save!
    Message.create!(channel: @channel, user: @creator, content: "Test")
    assert_difference("Message.count", -1) { @channel.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create channel" do
    assert_difference("Channel.count") { @channel.save! }
  end

  test "should update channel" do
    @channel.save!
    @channel.update!(description: "Updated description")
    assert_equal "Updated description", @channel.reload.description
  end

  test "should destroy channel" do
    @channel.save!
    assert_difference("Channel.count", -1) { @channel.destroy }
  end
end
