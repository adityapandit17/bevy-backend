require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  def setup
    @permission = Permission.new(
      name: "widgets.index",
      resource: "widgets",
      action: "index",
      description: "View widgets list"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @permission.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require name" do
    @permission.name = nil
    assert_not @permission.valid?
    assert_includes @permission.errors[:name], "can't be blank"
  end

  test "should require resource" do
    @permission.resource = nil
    assert_not @permission.valid?
    assert_includes @permission.errors[:resource], "can't be blank"
  end

  test "should require action" do
    @permission.action = nil
    assert_not @permission.valid?
    assert_includes @permission.errors[:action], "can't be blank"
  end

  # ── Uniqueness validations ────────────────────────────────────────────────
  test "should enforce unique name" do
    @permission.save!
    dup = Permission.new(name: @permission.name, resource: "other", action: "index")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "should enforce unique resource+action combination" do
    @permission.save!
    dup = Permission.new(name: "widgets.index.dup", resource: "widgets", action: "index")
    assert_not dup.valid?
    assert_includes dup.errors[:resource], "has already been taken"
  end

  test "should allow same action on different resources" do
    @permission.save!
    other = Permission.new(name: "gadgets.index", resource: "gadgets", action: "index")
    assert other.valid?
  end

  test "should allow different actions on same resource" do
    @permission.save!
    other = Permission.new(name: "widgets.create", resource: "widgets", action: "create")
    assert other.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should have many role_permissions" do
    assert_respond_to @permission, :role_permissions
  end

  test "should have many roles through role_permissions" do
    assert_respond_to @permission, :roles
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "by_resource scope filters by resource" do
    @permission.save!
    other = Permission.create!(name: "other.index", resource: "other", action: "index")
    assert_includes Permission.by_resource("widgets"), @permission
    assert_not_includes Permission.by_resource("widgets"), other
  end

  test "by_action scope filters by action" do
    @permission.save!
    other = Permission.create!(name: "widgets.create2", resource: "widgets2", action: "create")
    assert_includes Permission.by_action("index"), @permission
    assert_not_includes Permission.by_action("index"), other
  end

  test "by_resource_and_action scope filters by both" do
    @permission.save!
    result = Permission.by_resource_and_action("widgets", "index")
    assert_includes result, @permission
    assert_equal 1, result.where(resource: "widgets", action: "index").count
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "resource_action returns resource#action format" do
    assert_equal "widgets#index", @permission.resource_action
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "create_default_permissions creates expected permissions" do
    Permission.create_default_permissions
    assert Permission.exists?(resource: "employees", action: "index")
    assert Permission.exists?(resource: "payrolls", action: "create")
    assert Permission.exists?(resource: "leave_requests", action: "approve")
  end

  test "create_default_permissions is idempotent" do
    Permission.create_default_permissions
    count_before = Permission.count
    Permission.create_default_permissions
    assert_equal count_before, Permission.count
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "destroying permission destroys dependent role_permissions" do
    @permission.save!
    role = Role.create!(name: "PermRole#{SecureRandom.hex(4)}", description: "test")
    RolePermission.create!(role: role, permission: @permission)
    assert_difference("RolePermission.count", -1) { @permission.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create permission" do
    assert_difference("Permission.count") { @permission.save! }
  end

  test "should update permission" do
    @permission.save!
    @permission.update!(description: "Updated")
    assert_equal "Updated", @permission.reload.description
  end

  test "should destroy permission" do
    @permission.save!
    assert_difference("Permission.count", -1) { @permission.destroy }
  end
end
