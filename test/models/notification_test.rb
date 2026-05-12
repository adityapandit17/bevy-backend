require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @notification = Notification.new(
      user: @user,
      title: "Leave Request Approved",
      message: "Your annual leave request has been approved.",
      notification_type: "leave",
      read: false
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @notification.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @notification.title = nil
    assert_not @notification.valid?
    assert_includes @notification.errors[:title], "can't be blank"
  end

  test "should require message" do
    @notification.message = nil
    assert_not @notification.valid?
    assert_includes @notification.errors[:message], "can't be blank"
  end

  test "should require notification_type" do
    @notification.notification_type = nil
    assert_not @notification.valid?
    assert_includes @notification.errors[:notification_type], "can't be blank"
  end

  # ── Enum: notification_type ───────────────────────────────────────────────
  test "should accept all valid notification_types" do
    %w[leave attendance payroll system announcement reminder].each do |type|
      @notification.notification_type = type
      assert @notification.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid notification_type" do
    assert_raises(ArgumentError) do
      @notification.notification_type = "invalid_type"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to user" do
    assert_respond_to @notification, :user
  end

  test "should require user" do
    @notification.user = nil
    assert_not @notification.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "unread scope returns unread notifications" do
    @notification.read = false
    @notification.save!
    read_notification = Notification.create!(
      user: @user,
      title: "Read notification",
      message: "Already read",
      notification_type: "system",
      read: true
    )
    assert_includes Notification.unread, @notification
    assert_not_includes Notification.unread, read_notification
  end

  # ── Enum helper methods ───────────────────────────────────────────────────
  test "leave? returns true for leave notification" do
    @notification.notification_type = "leave"
    assert @notification.leave?
  end

  test "attendance? returns true for attendance notification" do
    @notification.notification_type = "attendance"
    assert @notification.attendance?
  end

  test "payroll? returns true for payroll notification" do
    @notification.notification_type = "payroll"
    assert @notification.payroll?
  end

  test "system? returns true for system notification" do
    @notification.notification_type = "system"
    assert @notification.system?
  end

  # ── Read / unread state ───────────────────────────────────────────────────
  test "should default to unread" do
    notification = Notification.new(
      user: @user,
      title: "New",
      message: "Test",
      notification_type: "system"
    )
    assert_not notification.read
  end

  test "should be markable as read" do
    @notification.save!
    @notification.update!(read: true)
    assert @notification.reload.read
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "should be destroyed when user is destroyed" do
    @notification.save!
    assert_difference("Notification.count", -1) { @user.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create notification" do
    assert_difference("Notification.count") { @notification.save! }
  end

  test "should update notification" do
    @notification.save!
    @notification.update!(read: true)
    assert @notification.reload.read
  end

  test "should destroy notification" do
    @notification.save!
    assert_difference("Notification.count", -1) { @notification.destroy }
  end
end
