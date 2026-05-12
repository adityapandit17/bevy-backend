require "test_helper"

class HelpdeskTicketTest < ActiveSupport::TestCase
  def setup
    @ticket = HelpdeskTicket.new(
      title: "Screen not working",
      description: "The monitor goes blank intermittently.",
      category: "hardware",
      priority: "high",
      status: "open",
      sla_status: "on-track",
      channel: "portal",
      sla_hours: 24
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @ticket.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @ticket.title = nil
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:title], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid priority" do
    @ticket.priority = "critical"
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:priority], "is not included in the list"
  end

  test "should accept all valid priorities" do
    %w[low medium high].each do |p|
      @ticket.priority = p
      assert @ticket.valid?, "#{p} should be valid"
    end
  end

  test "should reject invalid status" do
    @ticket.status = "archived"
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[open in-progress pending resolved closed].each do |s|
      @ticket.status = s
      assert @ticket.valid?, "#{s} should be valid"
    end
  end

  test "should reject invalid sla_status" do
    @ticket.sla_status = "green"
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:sla_status], "is not included in the list"
  end

  test "should accept all valid sla_statuses" do
    %w[on-track at-risk breached].each do |s|
      @ticket.sla_status = s
      assert @ticket.valid?, "#{s} should be valid"
    end
  end

  test "should reject invalid channel" do
    @ticket.channel = "chat"
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:channel], "is not included in the list"
  end

  test "should accept all valid channels" do
    %w[email phone portal system].each do |c|
      @ticket.channel = c
      assert @ticket.valid?, "#{c} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should optionally belong to assigned_to employee" do
    @ticket.assigned_to = nil
    assert @ticket.valid?
    assert_respond_to @ticket, :assigned_to
  end

  test "should optionally belong to requester employee" do
    @ticket.requester = nil
    assert @ticket.valid?
    assert_respond_to @ticket, :requester
  end

  test "should have many ticket_comments" do
    assert_respond_to @ticket, :ticket_comments
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "open scope returns open tickets" do
    @ticket.status = "open"
    @ticket.save!
    resolved = HelpdeskTicket.create!(
      title: "Resolved",
      priority: "low",
      status: "resolved",
      sla_status: "on-track",
      channel: "email"
    )
    assert_includes HelpdeskTicket.open, @ticket
    assert_not_includes HelpdeskTicket.open, resolved
  end

  test "resolved scope returns resolved tickets" do
    @ticket.status = "resolved"
    @ticket.save!
    assert_includes HelpdeskTicket.resolved, @ticket
  end

  test "high_priority scope returns high priority tickets" do
    @ticket.priority = "high"
    @ticket.save!
    low = HelpdeskTicket.create!(
      title: "Low priority",
      priority: "low",
      status: "open",
      sla_status: "on-track",
      channel: "email"
    )
    assert_includes HelpdeskTicket.high_priority, @ticket
    assert_not_includes HelpdeskTicket.high_priority, low
  end

  test "at_risk scope returns at-risk tickets" do
    @ticket.sla_status = "at-risk"
    @ticket.save!
    assert_includes HelpdeskTicket.at_risk, @ticket
  end

  test "breached scope returns breached tickets" do
    @ticket.sla_status = "breached"
    @ticket.save!
    assert_includes HelpdeskTicket.breached, @ticket
  end

  test "by_priority scope filters by priority" do
    @ticket.priority = "medium"
    @ticket.save!
    assert_includes HelpdeskTicket.by_priority("medium"), @ticket
  end

  test "by_status scope filters by status" do
    @ticket.status = "pending"
    @ticket.save!
    assert_includes HelpdeskTicket.by_status("pending"), @ticket
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "tags_list parses comma-separated tags string" do
    @ticket.tags = "hardware, monitor, urgent"
    @ticket.save!
    assert_includes @ticket.tags_list, "hardware"
    assert_includes @ticket.tags_list, "monitor"
    assert_equal 3, @ticket.tags_list.length
  end

  test "tags_list parses JSON array tags" do
    @ticket.tags = '["hardware", "monitor"]'
    @ticket.save!
    assert_equal [ "hardware", "monitor" ], @ticket.tags_list
  end

  test "tags_list returns empty array when tags is blank" do
    @ticket.tags = nil
    assert_equal [], @ticket.tags_list
  end

  test "tags_list= assigns array as comma-separated string" do
    @ticket.tags_list = %w[urgent vip]
    assert_equal "urgent, vip", @ticket.tags
  end

  test "sla_display returns formatted hours" do
    @ticket.sla_hours = 8
    assert_equal "8h", @ticket.sla_display
  end

  test "sla_display returns N/A when sla_hours is blank" do
    @ticket.sla_hours = nil
    assert_equal "N/A", @ticket.sla_display
  end

  test "assigned_to_name returns Unassigned when no employee" do
    @ticket.assigned_to = nil
    assert_equal "Unassigned", @ticket.assigned_to_name
  end

  test "requester_name returns Unknown when no requester" do
    @ticket.requester = nil
    assert_equal "Unknown", @ticket.requester_name
  end

  # ── SLA callback ─────────────────────────────────────────────────────────
  test "sla_status stays on-track when plenty of time remains" do
    @ticket.sla_hours = 100
    @ticket.save!
    assert_equal "on-track", @ticket.reload.sla_status
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "destroying ticket destroys dependent comments" do
    @ticket.save!
    TicketComment.create!(helpdesk_ticket: @ticket, content: "Test comment")
    assert_difference("TicketComment.count", -1) { @ticket.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create helpdesk ticket" do
    assert_difference("HelpdeskTicket.count") { @ticket.save! }
  end

  test "should update helpdesk ticket" do
    @ticket.save!
    @ticket.update!(status: "in-progress")
    assert_equal "in-progress", @ticket.reload.status
  end

  test "should destroy helpdesk ticket" do
    @ticket.save!
    assert_difference("HelpdeskTicket.count", -1) { @ticket.destroy }
  end
end
