require "test_helper"

class RoleTest < ActiveSupport::TestCase
  def setup
    @role = Role.new(name: "Test Role #{SecureRandom.hex(4)}", description: "A test role")
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @role.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require name" do
    @role.name = nil
    assert_not @role.valid?
    assert_includes @role.errors[:name], "can't be blank"
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique name" do
    @role.save!
    dup = Role.new(name: @role.name, description: "duplicate")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should have many user_roles" do
    assert_respond_to @role, :user_roles
  end

  test "should have many users through user_roles" do
    assert_respond_to @role, :users
  end

  test "should have many role_permissions" do
    assert_respond_to @role, :role_permissions
  end

  test "should have many permissions through role_permissions" do
    assert_respond_to @role, :permissions
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "by_name scope filters by name" do
    @role.save!
    assert_includes Role.by_name(@role.name), @role
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "add_permission adds permission to role" do
    @role.save!
    perm = Permission.find_or_create_by!(resource: "employees", action: "index") do |p|
      p.name = "employees.index"
    end
    @role.add_permission(perm)
    assert_includes @role.permissions, perm
  end

  test "add_permission does not duplicate an existing permission" do
    @role.save!
    perm = Permission.find_or_create_by!(resource: "employees", action: "show") do |p|
      p.name = "employees.show"
    end
    @role.add_permission(perm)
    @role.add_permission(perm)
    assert_equal 1, @role.permissions.where(id: perm.id).count
  end

  test "remove_permission removes permission from role" do
    @role.save!
    perm = Permission.find_or_create_by!(resource: "employees", action: "create") do |p|
      p.name = "employees.create"
    end
    @role.add_permission(perm)
    @role.remove_permission(perm)
    assert_not_includes @role.permissions, perm
  end

  test "has_permission? returns true when permission exists" do
    @role.save!
    perm = Permission.find_or_create_by!(resource: "employees", action: "update") do |p|
      p.name = "employees.update"
    end
    @role.add_permission(perm)
    assert @role.has_permission?("employees", "update")
  end

  test "has_permission? returns false when permission does not exist" do
    @role.save!
    assert_not @role.has_permission?("employees", "destroy")
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "create_default_roles creates all expected roles" do
    Role.create_default_roles
    %w[Super\ Admin HR\ Manager Department\ Head Employee IT\ Asset\ Manager IT\ Support].each do |name|
      assert Role.exists?(name: name), "Expected role '#{name}' to exist"
    end
  end

  test "create_default_roles is idempotent" do
    Role.create_default_roles
    count_before = Role.count
    Role.create_default_roles
    assert_equal count_before, Role.count
  end

  # ── Dependent destroy ─────────────────────────────────────────────────────
  test "destroying role destroys dependent role_permissions" do
    @role.save!
    perm = Permission.find_or_create_by!(resource: "assets", action: "index") do |p|
      p.name = "assets.index"
    end
    @role.add_permission(perm)
    assert_difference("RolePermission.count", -1) { @role.destroy }
  end

  test "destroying role destroys dependent user_roles" do
    @role.save!
    user = users(:one)
    user.roles << @role
    assert_difference("UserRole.count", -1) { @role.destroy }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create role" do
    assert_difference("Role.count") { @role.save! }
  end

  test "should update role" do
    @role.save!
    @role.update!(description: "Updated description")
    assert_equal "Updated description", @role.reload.description
  end

  test "should destroy role" do
    @role.save!
    assert_difference("Role.count", -1) { @role.destroy }
  end
end
