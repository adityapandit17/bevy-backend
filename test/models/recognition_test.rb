require "test_helper"

class RecognitionTest < ActiveSupport::TestCase
  def setup
    @giver = users(:one)
    @receiver = employees(:one)
    @recognition = Recognition.new(
      given_by: @giver,
      received_by: @receiver,
      title: "Outstanding Delivery",
      recognition_type: "achievement",
      message: "Delivered the project ahead of schedule.",
      status: "active"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @recognition.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @recognition.title = nil
    assert_not @recognition.valid?
    assert_includes @recognition.errors[:title], "can't be blank"
  end

  test "should require recognition_type" do
    @recognition.recognition_type = nil
    assert_not @recognition.valid?
    assert_includes @recognition.errors[:recognition_type], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid recognition_type" do
    @recognition.recognition_type = "bonus"
    assert_not @recognition.valid?
    assert_includes @recognition.errors[:recognition_type], "is not included in the list"
  end

  test "should accept all valid recognition_types" do
    %w[appreciation achievement milestone excellence teamwork innovation leadership].each do |type|
      @recognition.recognition_type = type
      assert @recognition.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid status" do
    @recognition.status = "pending"
    assert_not @recognition.valid?
    assert_includes @recognition.errors[:status], "is not included in the list"
  end

  test "should accept active and archived statuses" do
    %w[active archived].each do |s|
      @recognition.status = s
      assert @recognition.valid?, "#{s} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to given_by user" do
    assert_respond_to @recognition, :given_by
  end

  test "should require given_by" do
    @recognition.given_by = nil
    assert_not @recognition.valid?
  end

  test "should belong to received_by employee" do
    assert_respond_to @recognition, :received_by
  end

  test "should require received_by" do
    @recognition.received_by = nil
    assert_not @recognition.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active recognitions" do
    @recognition.status = "active"
    @recognition.save!
    archived = Recognition.create!(
      given_by: @giver,
      received_by: employees(:two),
      title: "Archived",
      recognition_type: "appreciation",
      status: "archived"
    )
    assert_includes Recognition.active, @recognition
    assert_not_includes Recognition.active, archived
  end

  test "archived scope returns archived recognitions" do
    @recognition.status = "archived"
    @recognition.save!
    assert_includes Recognition.archived, @recognition
  end

  test "by_type scope filters by recognition_type" do
    @recognition.recognition_type = "achievement"
    @recognition.save!
    assert_includes Recognition.by_type("achievement"), @recognition
  end

  test "by_employee scope filters by received_by_id" do
    @recognition.save!
    assert_includes Recognition.by_employee(@receiver.id), @recognition
  end

  test "by_giver scope filters by given_by_id" do
    @recognition.save!
    assert_includes Recognition.by_giver(@giver.id), @recognition
  end

  test "recent scope orders by created_at descending" do
    @recognition.save!
    second = Recognition.create!(
      given_by: @giver,
      received_by: employees(:two),
      title: "Another Award",
      recognition_type: "teamwork",
      status: "active"
    )
    assert_equal second, Recognition.recent.first
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "given_by_name returns user name" do
    assert_equal @giver.name, @recognition.given_by_name
  end

  test "received_by_name returns employee full name" do
    expected = "#{@receiver.first_name} #{@receiver.last_name}"
    assert_equal expected, @recognition.received_by_name
  end

  test "formatted_date returns readable date after save" do
    @recognition.save!
    assert_not_nil @recognition.formatted_date
    assert_match(/\A\w+ \d{1,2}, \d{4}\z/, @recognition.formatted_date)
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "categories returns list of categories" do
    cats = Recognition.categories
    assert_includes cats, "performance"
    assert_includes cats, "teamwork"
    assert cats.is_a?(Array)
  end

  test "types returns list of recognition types" do
    types = Recognition.types
    assert_includes types, "achievement"
    assert_includes types, "innovation"
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create recognition" do
    assert_difference("Recognition.count") { @recognition.save! }
  end

  test "should update recognition" do
    @recognition.save!
    @recognition.update!(title: "Updated Award")
    assert_equal "Updated Award", @recognition.reload.title
  end

  test "should destroy recognition" do
    @recognition.save!
    assert_difference("Recognition.count", -1) { @recognition.destroy }
  end
end
