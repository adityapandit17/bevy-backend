require "test_helper"

class HuddleTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @channel = channels(:one)
    @huddle = Huddle.new(
      channel: @channel,
      started_by: @user,
      status: "active",
      started_at: Time.current
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @huddle.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require status" do
    @huddle.status = nil
    assert_not @huddle.valid?
    assert_includes @huddle.errors[:status], "can't be blank"
  end

  test "should require started_at" do
    @huddle.started_at = nil
    assert_not @huddle.valid?
    assert_includes @huddle.errors[:started_at], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @huddle.status = "paused"
    assert_not @huddle.valid?
    assert_includes @huddle.errors[:status], "is not included in the list"
  end

  test "should accept active and ended statuses" do
    %w[active ended].each do |s|
      @huddle.status = s
      assert @huddle.valid?, "#{s} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to channel" do
    assert_respond_to @huddle, :channel
  end

  test "should belong to started_by user" do
    assert_respond_to @huddle, :started_by
  end

  test "should have many huddle_participants" do
    assert_respond_to @huddle, :huddle_participants
  end

  test "should have many participants through huddle_participants" do
    assert_respond_to @huddle, :participants
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active huddles" do
    @huddle.status = "active"
    @huddle.save!
    ended = Huddle.create!(
      channel: channels(:two),
      started_by: users(:two),
      status: "ended",
      started_at: 1.hour.ago
    )
    assert_includes Huddle.active, @huddle
    assert_not_includes Huddle.active, ended
  end

  test "ended scope returns ended huddles" do
    @huddle.status = "ended"
    @huddle.save!
    assert_includes Huddle.ended, @huddle
  end

  test "for_channel scope filters by channel" do
    @huddle.save!
    assert_includes Huddle.for_channel(@channel.id), @huddle
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "active? returns true when status is active" do
    @huddle.status = "active"
    assert @huddle.active?
  end

  test "active? returns false when status is ended" do
    @huddle.status = "ended"
    assert_not @huddle.active?
  end

  test "add_participant creates a huddle_participant" do
    @huddle.save!
    assert_difference("HuddleParticipant.count") do
      @huddle.add_participant(@user)
    end
  end

  test "add_participant is idempotent" do
    @huddle.save!
    @huddle.add_participant(@user)
    assert_no_difference("HuddleParticipant.count") do
      @huddle.add_participant(@user)
    end
  end

  test "remove_participant sets left_at for participant" do
    @huddle.save!
    @huddle.add_participant(@user)
    @huddle.remove_participant(@user)
    participant = HuddleParticipant.find_by(huddle: @huddle, user: @user)
    assert_not_nil participant.left_at
  end

  test "active_participants returns participants who have not left" do
    @huddle.save!
    @huddle.add_participant(@user)
    assert_equal 1, @huddle.active_participants.count
    @huddle.remove_participant(@user)
    assert_equal 0, @huddle.active_participants.count
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "destroying huddle destroys dependent huddle_participants" do
    @huddle.save!
    @huddle.add_participant(@user)
    assert_difference("HuddleParticipant.count", -1) { @huddle.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create huddle" do
    assert_difference("Huddle.count") { @huddle.save! }
  end

  test "should update huddle" do
    @huddle.save!
    @huddle.update!(status: "ended", ended_at: Time.current)
    assert_equal "ended", @huddle.reload.status
  end

  test "should destroy huddle" do
    @huddle.save!
    assert_difference("Huddle.count", -1) { @huddle.destroy }
  end
end
