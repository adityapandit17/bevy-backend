require "test_helper"

class TicketCommentTest < ActiveSupport::TestCase
  def setup
    @ticket = HelpdeskTicket.create!(
      title: "Test Ticket",
      priority: "medium",
      status: "open",
      sla_status: "on-track",
      channel: "portal"
    )
    @user = users(:one)
    @employee = employees(:one)
    @comment = TicketComment.new(
      helpdesk_ticket: @ticket,
      content: "Looking into the issue now.",
      user: @user
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "should be valid with only employee (no user)" do
    @comment.user = nil
    @comment.employee = @employee
    assert @comment.valid?
  end

  test "should be valid with neither user nor employee" do
    @comment.user = nil
    @comment.employee = nil
    assert @comment.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require content" do
    @comment.content = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:content], "can't be blank"
  end

  test "should require helpdesk_ticket_id" do
    @comment.helpdesk_ticket = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:helpdesk_ticket_id], "can't be blank"
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to helpdesk_ticket" do
    assert_respond_to @comment, :helpdesk_ticket
  end

  test "should optionally belong to user" do
    assert_respond_to @comment, :user
  end

  test "should optionally belong to employee" do
    assert_respond_to @comment, :employee
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "recent scope orders by created_at descending" do
    @comment.save!
    newer = TicketComment.create!(
      helpdesk_ticket: @ticket,
      content: "Follow-up comment",
      user: @user
    )
    assert_equal newer, TicketComment.recent.first
  end

  test "oldest_first scope orders by created_at ascending" do
    @comment.save!
    newer = TicketComment.create!(
      helpdesk_ticket: @ticket,
      content: "Follow-up comment",
      user: @user
    )
    assert_equal @comment, TicketComment.oldest_first.first
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "author_name returns user name when user is present" do
    @comment.user = @user
    @comment.employee = nil
    assert_equal @user.name, @comment.author_name
  end

  test "author_name returns employee full name when employee is present" do
    @comment.user = nil
    @comment.employee = @employee
    expected = "#{@employee.first_name} #{@employee.last_name}".strip
    assert_equal expected, @comment.author_name
  end

  test "author_name returns Unknown when neither user nor employee" do
    @comment.user = nil
    @comment.employee = nil
    assert_equal "Unknown", @comment.author_name
  end

  test "author_email returns user email when user is present" do
    @comment.user = @user
    @comment.employee = nil
    assert_equal @user.email, @comment.author_email
  end

  test "author_email returns employee email when employee is present" do
    @comment.user = nil
    @comment.employee = @employee
    assert_equal @employee.email, @comment.author_email
  end

  test "author_email returns nil when neither user nor employee" do
    @comment.user = nil
    @comment.employee = nil
    assert_nil @comment.author_email
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create ticket comment" do
    assert_difference("TicketComment.count") { @comment.save! }
  end

  test "should update ticket comment" do
    @comment.save!
    @comment.update!(content: "Updated content")
    assert_equal "Updated content", @comment.reload.content
  end

  test "should destroy ticket comment" do
    @comment.save!
    assert_difference("TicketComment.count", -1) { @comment.destroy }
  end
end
