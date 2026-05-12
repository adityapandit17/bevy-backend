require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  def setup
    @role = Role.find_or_create_by!(name: "RPTestRole#{SecureRandom.hex(4)}") do |r|
      r.description = "test"
    end
    @permission = Permission.find_or_create_by!(resource: "rp_widgets", action: "index") do |p|
      p.name = "rp_widgets.index"
    end
    @role_permission = RolePermission.new(role: @role, permission: @permission)
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @role_permission.valid?
  end

  # ── Presence / association validations ───────────────────────────────────
  test "should require role" do
    @role_permission.role = nil
    assert_not @role_permission.valid?
  end

  test "should require permission" do
    @role_permission.permission = nil
    assert_not @role_permission.valid?
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique role_id + permission_id" do
    @role_permission.save!
    dup = RolePermission.new(role: @role, permission: @permission)
    assert_not dup.valid?
    assert_includes dup.errors[:role_id], "has already been taken"
  end

  test "should allow same permission on different roles" do
    @role_permission.save!
    other_role = Role.create!(name: "OtherRPRole#{SecureRandom.hex(4)}", description: "other")
    other_rp = RolePermission.new(role: other_role, permission: @permission)
    assert other_rp.valid?
  end

  test "should allow same role with different permissions" do
    @role_permission.save!
    other_perm = Permission.find_or_create_by!(resource: "rp_widgets", action: "create") do |p|
      p.name = "rp_widgets.create"
    end
    other_rp = RolePermission.new(role: @role, permission: other_perm)
    assert other_rp.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to role" do
    assert_respond_to @role_permission, :role
  end

  test "should belong to permission" do
    assert_respond_to @role_permission, :permission
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create role_permission" do
    assert_difference("RolePermission.count") { @role_permission.save! }
  end

  test "should destroy role_permission" do
    @role_permission.save!
    assert_difference("RolePermission.count", -1) { @role_permission.destroy }
  end

  test "assigning permission via role helper reflects in role_permissions" do
    @role_permission.save!
    assert_includes @role.permissions, @permission
  end

  test "removing permission via role helper destroys role_permission" do
    @role_permission.save!
    @role.remove_permission(@permission)
    assert_not RolePermission.exists?(role: @role, permission: @permission)
  end
end
