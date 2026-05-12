require "test_helper"

class HuddleParticipantTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @huddle = huddles(:one)
    @participant = HuddleParticipant.new(
      huddle: @huddle,
      user: @user,
      joined_at: Time.current
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @participant.valid?
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique user per huddle" do
    @participant.save!
    dup = HuddleParticipant.new(huddle: @huddle, user: @user)
    assert_not dup.valid?
    assert dup.errors[:user_id].any?
  end

  test "should allow same user in different huddles" do
    @participant.save!
    other_huddle = huddles(:two)
    other = HuddleParticipant.new(huddle: other_huddle, user: @user, joined_at: Time.current)
    assert other.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to huddle" do
    assert_respond_to @participant, :huddle
  end

  test "should belong to user" do
    assert_respond_to @participant, :user
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns participants who have not left" do
    @participant.left_at = nil
    @participant.save!
    assert_includes HuddleParticipant.active, @participant
  end

  test "inactive scope returns participants who have left" do
    @participant.left_at = 1.hour.ago
    @participant.save!
    assert_includes HuddleParticipant.inactive, @participant
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create huddle_participant" do
    assert_difference("HuddleParticipant.count") { @participant.save! }
  end

  test "should update left_at on participant" do
    @participant.save!
    @participant.update!(left_at: Time.current)
    assert_not_nil @participant.reload.left_at
  end

  test "should destroy huddle_participant" do
    @participant.save!
    assert_difference("HuddleParticipant.count", -1) { @participant.destroy }
  end
end
