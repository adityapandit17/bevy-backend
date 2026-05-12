require "test_helper"

class ChannelMembershipTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @channel = channels(:one)
    @membership = ChannelMembership.new(
      channel: @channel,
      user: @user,
      role: "member"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @membership.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require role" do
    @membership.role = nil
    assert_not @membership.valid?
    assert_includes @membership.errors[:role], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid role" do
    @membership.role = "owner"
    assert_not @membership.valid?
    assert_includes @membership.errors[:role], "is not included in the list"
  end

  test "should accept admin and member roles" do
    %w[admin member].each do |r|
      @membership.role = r
      assert @membership.valid?, "#{r} should be valid"
    end
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique user per channel" do
    @membership.save!
    dup = ChannelMembership.new(channel: @channel, user: @user, role: "admin")
    assert_not dup.valid?
    assert dup.errors[:user_id].any?
  end

  test "should allow same user in different channels" do
    @membership.save!
    other_channel = channels(:two)
    other = ChannelMembership.new(channel: other_channel, user: @user, role: "member")
    assert other.valid?
  end

  test "should allow different users in same channel" do
    @membership.save!
    other = ChannelMembership.new(channel: @channel, user: users(:two), role: "member")
    assert other.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to channel" do
    assert_respond_to @membership, :channel
  end

  test "should belong to user" do
    assert_respond_to @membership, :user
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "admins scope returns admin memberships" do
    @membership.role = "admin"
    @membership.save!
    assert_includes ChannelMembership.admins, @membership
  end

  test "members scope returns member memberships" do
    @membership.role = "member"
    @membership.save!
    assert_includes ChannelMembership.members, @membership
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "mark_as_read! updates last_read_at" do
    @membership.save!
    @membership.mark_as_read!
    assert_not_nil @membership.reload.last_read_at
    assert_in_delta Time.current.to_f, @membership.reload.last_read_at.to_f, 5
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create channel membership" do
    assert_difference("ChannelMembership.count") { @membership.save! }
  end

  test "should update role" do
    @membership.save!
    @membership.update!(role: "admin")
    assert_equal "admin", @membership.reload.role
  end

  test "should destroy channel membership" do
    @membership.save!
    assert_difference("ChannelMembership.count", -1) { @membership.destroy }
  end
end
