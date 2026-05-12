require "test_helper"

class SlaWorkflowTest < ActiveSupport::TestCase
  def setup
    @workflow = SlaWorkflow.new(
      name: "Standard Hardware SLA",
      priority: "medium",
      status: "active",
      sla_hours: 24,
      category: "hardware",
      description: "Standard SLA for hardware issues"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @workflow.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require name" do
    @workflow.name = nil
    assert_not @workflow.valid?
    assert_includes @workflow.errors[:name], "can't be blank"
  end

  test "should require sla_hours" do
    @workflow.sla_hours = nil
    assert_not @workflow.valid?
    assert_includes @workflow.errors[:sla_hours], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid priority" do
    @workflow.priority = "critical"
    assert_not @workflow.valid?
    assert_includes @workflow.errors[:priority], "is not included in the list"
  end

  test "should accept all valid priorities" do
    %w[low medium high].each do |p|
      @workflow.priority = p
      assert @workflow.valid?, "#{p} should be valid"
    end
  end

  test "should reject invalid status" do
    @workflow.status = "archived"
    assert_not @workflow.valid?
    assert_includes @workflow.errors[:status], "is not included in the list"
  end

  test "should accept active and inactive statuses" do
    %w[active inactive].each do |s|
      @workflow.status = s
      assert @workflow.valid?, "#{s} should be valid"
    end
  end

  # ── Numericality validation ───────────────────────────────────────────────
  test "should reject sla_hours of 0 or less" do
    @workflow.sla_hours = 0
    assert_not @workflow.valid?
    @workflow.sla_hours = -1
    assert_not @workflow.valid?
  end

  test "should accept positive sla_hours" do
    @workflow.sla_hours = 1
    assert @workflow.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns only active workflows" do
    @workflow.save!
    inactive = SlaWorkflow.create!(
      name: "Inactive SLA",
      priority: "low",
      status: "inactive",
      sla_hours: 48
    )
    assert_includes SlaWorkflow.active, @workflow
    assert_not_includes SlaWorkflow.active, inactive
  end

  test "inactive scope returns only inactive workflows" do
    @workflow.status = "inactive"
    @workflow.save!
    assert_includes SlaWorkflow.inactive, @workflow
  end

  test "by_category scope filters by category" do
    @workflow.save!
    other = SlaWorkflow.create!(
      name: "Software SLA",
      priority: "high",
      status: "active",
      sla_hours: 8,
      category: "software"
    )
    assert_includes SlaWorkflow.by_category("hardware"), @workflow
    assert_not_includes SlaWorkflow.by_category("hardware"), other
  end

  test "by_priority scope filters by priority" do
    @workflow.priority = "high"
    @workflow.save!
    assert_includes SlaWorkflow.by_priority("high"), @workflow
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "sla_display returns formatted hours" do
    @workflow.sla_hours = 24
    assert_equal "24h", @workflow.sla_display
  end

  test "avg_resolution_display returns N/A when blank" do
    @workflow.avg_resolution_hours = nil
    assert_equal "N/A", @workflow.avg_resolution_display
  end

  test "avg_resolution_display returns formatted hours when present" do
    @workflow.avg_resolution_hours = 18.5
    assert_equal "18h", @workflow.avg_resolution_display
  end

  test "escalation_levels_list returns empty array when blank" do
    @workflow.escalation_levels = nil
    assert_equal [], @workflow.escalation_levels_list
  end

  test "escalation_levels_list parses JSON array" do
    @workflow.escalation_levels = '[{"level": 1, "action": "notify_manager"}]'
    levels = @workflow.escalation_levels_list
    assert_equal 1, levels.length
    assert_equal 1, levels.first["level"]
  end

  test "escalation_levels_list= stores JSON array" do
    @workflow.escalation_levels_list = [{ "level" => 1, "action" => "notify" }]
    assert_includes @workflow.escalation_levels, "notify"
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create sla_workflow" do
    assert_difference("SlaWorkflow.count") { @workflow.save! }
  end

  test "should update sla_workflow" do
    @workflow.save!
    @workflow.update!(sla_hours: 48)
    assert_equal 48, @workflow.reload.sla_hours.to_i
  end

  test "should destroy sla_workflow" do
    @workflow.save!
    assert_difference("SlaWorkflow.count", -1) { @workflow.destroy }
  end
end
