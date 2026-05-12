require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @organizer = users(:one)
    @event = Event.new(
      title: "Team Kickoff",
      description: "Q3 kickoff meeting",
      event_type: "meeting",
      start_time: 1.day.from_now.change(hour: 10, min: 0),
      end_time: 1.day.from_now.change(hour: 11, min: 0),
      location: "Main Conference Room",
      organizer: @organizer,
      status: "scheduled"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @event.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @event.title = nil
    assert_not @event.valid?
    assert_includes @event.errors[:title], "can't be blank"
  end

  test "should require start_time" do
    @event.start_time = nil
    assert_not @event.valid?
    assert_includes @event.errors[:start_time], "can't be blank"
  end

  test "should require end_time" do
    @event.end_time = nil
    assert_not @event.valid?
    assert_includes @event.errors[:end_time], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid event_type" do
    @event.event_type = "webinar"
    assert_not @event.valid?
    assert_includes @event.errors[:event_type], "is not included in the list"
  end

  test "should accept all valid event_types" do
    %w[meeting event training workshop other].each do |type|
      @event.event_type = type
      assert @event.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid status" do
    @event.status = "draft"
    assert_not @event.valid?
    assert_includes @event.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[scheduled cancelled completed postponed].each do |s|
      @event.status = s
      assert @event.valid?, "#{s} should be valid"
    end
  end

  # ── Custom validation: end_time after start_time ─────────────────────────
  test "should reject end_time before start_time" do
    @event.end_time = @event.start_time - 1.hour
    assert_not @event.valid?
    assert_includes @event.errors[:end_time], "must be after start time"
  end

  test "should reject end_time equal to start_time" do
    @event.end_time = @event.start_time
    assert_not @event.valid?
    assert_includes @event.errors[:end_time], "must be after start time"
  end

  test "should accept end_time after start_time" do
    @event.end_time = @event.start_time + 1.hour
    assert @event.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should optionally belong to organizer" do
    @event.organizer = nil
    assert @event.valid?
  end

  test "should respond to organizer" do
    assert_respond_to @event, :organizer
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "upcoming scope returns events in the future" do
    @event.save!
    past_event = Event.create!(
      title: "Past Event",
      event_type: "meeting",
      start_time: 2.days.ago,
      end_time: 2.days.ago + 1.hour,
      status: "completed"
    )
    assert_includes Event.upcoming, @event
    assert_not_includes Event.upcoming, past_event
  end

  test "scheduled scope returns scheduled events" do
    @event.status = "scheduled"
    @event.save!
    assert_includes Event.scheduled, @event
  end

  test "by_type scope filters by event_type" do
    @event.event_type = "training"
    @event.save!
    meeting = Event.create!(
      title: "Meeting",
      event_type: "meeting",
      start_time: 2.days.from_now,
      end_time: 2.days.from_now + 1.hour,
      status: "scheduled"
    )
    assert_includes Event.by_type("training"), @event
    assert_not_includes Event.by_type("training"), meeting
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "duration_hours calculates event duration" do
    @event.start_time = Time.current.change(hour: 9)
    @event.end_time = Time.current.change(hour: 11)
    assert_in_delta 2.0, @event.duration_hours, 0.01
  end

  test "is_upcoming? returns true for future events" do
    @event.start_time = 1.day.from_now
    assert @event.is_upcoming?
  end

  test "is_past? returns true when end_time has passed" do
    @event.start_time = 2.days.ago
    @event.end_time = 1.day.ago
    assert @event.is_past?
  end

  test "formatted_start_time returns readable datetime" do
    @event.start_time = Time.new(2024, 6, 15, 10, 30, 0)
    assert_includes @event.formatted_start_time, "June 15, 2024"
  end

  test "attendee_ids_list returns empty array when nil" do
    @event.attendee_ids = nil
    assert_equal [], @event.attendee_ids_list
  end

  test "attendee_ids_list= stores array" do
    @event.attendee_ids_list = [1, 2, 3]
    assert_equal [1, 2, 3], @event.attendee_ids_list
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create event" do
    assert_difference("Event.count") { @event.save! }
  end

  test "should update event" do
    @event.save!
    @event.update!(title: "Updated Kickoff")
    assert_equal "Updated Kickoff", @event.reload.title
  end

  test "should destroy event" do
    @event.save!
    assert_difference("Event.count", -1) { @event.destroy }
  end
end
