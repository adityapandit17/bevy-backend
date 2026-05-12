require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "newuser@example.com",
      password: "password123",
      first_name: "New",
      last_name: "User",
      status: "active"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require first_name" do
    @user.first_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    @user.last_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "can't be blank"
  end

  test "should require status" do
    @user.status = nil
    assert_not @user.valid?
    assert_includes @user.errors[:status], "can't be blank"
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @user.status = "banned"
    assert_not @user.valid?
    assert_includes @user.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[active inactive suspended].each do |s|
      @user.status = s
      assert @user.valid?, "#{s} should be valid"
    end
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique email" do
    @user.save!
    dup = User.new(
      email: @user.email,
      password: "password123",
      first_name: "Dup",
      last_name: "User",
      status: "active"
    )
    assert_not dup.valid?
    assert_includes dup.errors[:email], "has already been taken"
  end

  # ── Email normalisation callback ──────────────────────────────────────────
  test "should downcase email before save" do
    @user.email = "UPPER@EXAMPLE.COM"
    @user.save!
    assert_equal "upper@example.com", @user.reload.email
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should have many user_roles" do
    assert_respond_to @user, :user_roles
  end

  test "should have many roles through user_roles" do
    assert_respond_to @user, :roles
  end

  test "should have many notifications" do
    assert_respond_to @user, :notifications
  end

  test "should optionally belong to employee" do
    assert_respond_to @user, :employee
    assert @user.valid?
  end

  test "should have one user_preference" do
    assert_respond_to @user, :user_preference
  end

  test "should have many channel_memberships" do
    assert_respond_to @user, :channel_memberships
  end

  test "should have many channels through channel_memberships" do
    assert_respond_to @user, :channels
  end

  test "should have many created_channels" do
    assert_respond_to @user, :created_channels
  end

  test "should have many messages" do
    assert_respond_to @user, :messages
  end

  test "should have many started_huddles" do
    assert_respond_to @user, :started_huddles
  end

  test "should have many huddle_participants" do
    assert_respond_to @user, :huddle_participants
  end

  test "should have many huddles through huddle_participants" do
    assert_respond_to @user, :huddles
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns only active users" do
    @user.save!
    inactive = users(:inactive)
    assert_includes User.active, @user
    assert_not_includes User.active, inactive
  end

  test "inactive scope returns only inactive users" do
    inactive = users(:inactive)
    @user.status = "active"
    @user.save!
    assert_includes User.inactive, inactive
    assert_not_includes User.inactive, @user
  end

  test "suspended scope returns only suspended users" do
    suspended = users(:suspended)
    @user.save!
    assert_includes User.suspended, suspended
    assert_not_includes User.suspended, @user
  end

  test "super_admins scope returns users with Super Admin role" do
    role = Role.find_or_create_by!(name: "Super Admin") { |r| r.description = "Full access" }
    @user.save!
    @user.roles << role
    assert_includes User.super_admins, @user
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "name returns full name" do
    assert_equal "New User", @user.name
  end

  test "active? returns true when status is active" do
    @user.status = "active"
    assert @user.active?
  end

  test "active? returns false when not active" do
    @user.status = "inactive"
    assert_not @user.active?
  end

  test "inactive? returns true when status is inactive" do
    @user.status = "inactive"
    assert @user.inactive?
  end

  test "suspended? returns true when status is suspended" do
    @user.status = "suspended"
    assert @user.suspended?
  end

  test "has_role? returns true when user has the role" do
    role = Role.find_or_create_by!(name: "Employee") { |r| r.description = "Self-service" }
    @user.save!
    @user.roles << role
    assert @user.has_role?("Employee")
  end

  test "has_role? returns false when user lacks the role" do
    @user.save!
    assert_not @user.has_role?("NonExistentRole")
  end

  test "super_admin? returns true when user has Super Admin role" do
    role = Role.find_or_create_by!(name: "Super Admin") { |r| r.description = "Full access" }
    @user.save!
    @user.roles << role
    assert @user.super_admin?
  end

  test "hr_manager? returns true when user has HR Manager role" do
    role = Role.find_or_create_by!(name: "HR Manager") { |r| r.description = "HR access" }
    @user.save!
    @user.roles << role
    assert @user.hr_manager?
  end

  test "has_permission? returns true when role has permission" do
    @user.save!
    role = Role.create!(name: "TestRole#{SecureRandom.hex(4)}", description: "test")
    perm = Permission.find_or_create_by!(resource: "employees", action: "index") do |p|
      p.name = "employees.index"
    end
    RolePermission.find_or_create_by!(role: role, permission: perm)
    @user.roles << role
    assert @user.has_permission?("employees", "index")
  end

  test "has_permission? returns false when user has no roles" do
    @user.save!
    assert_not @user.has_permission?("employees", "destroy")
  end

  test "has_permission? grants employees.index via payroll index access" do
    @user.save!
    role = Role.create!(name: "PayrollRole#{SecureRandom.hex(4)}", description: "payroll")
    perm = Permission.find_or_create_by!(resource: "payrolls", action: "index") do |p|
      p.name = "payrolls.index"
    end
    RolePermission.find_or_create_by!(role: role, permission: perm)
    @user.roles << role
    assert @user.has_permission?("employees", "index")
  end

  test "update_last_login! sets last_login_at" do
    @user.save!
    @user.update_last_login!
    assert_not_nil @user.reload.last_login_at
  end

  test "can_access_module? returns true when user has index permission" do
    @user.save!
    role = Role.create!(name: "ModuleRole#{SecureRandom.hex(4)}", description: "module")
    perm = Permission.find_or_create_by!(resource: "assets", action: "index") do |p|
      p.name = "assets.index"
    end
    RolePermission.find_or_create_by!(role: role, permission: perm)
    @user.roles << role
    assert @user.can_access_module?("assets")
  end

  test "can_manage_module? returns true when user has create permission" do
    @user.save!
    role = Role.create!(name: "ManageRole#{SecureRandom.hex(4)}", description: "manage")
    perm = Permission.find_or_create_by!(resource: "assets", action: "create") do |p|
      p.name = "assets.create"
    end
    RolePermission.find_or_create_by!(role: role, permission: perm)
    @user.roles << role
    assert @user.can_manage_module?("assets")
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create user" do
    assert_difference("User.count") { @user.save! }
  end

  test "should update user" do
    @user.save!
    @user.update!(first_name: "Updated")
    assert_equal "Updated", @user.reload.first_name
  end

  test "should destroy user" do
    @user.save!
    assert_difference("User.count", -1) { @user.destroy }
  end

  test "destroying user destroys dependent user_roles" do
    @user.save!
    role = Role.find_or_create_by!(name: "Employee") { |r| r.description = "Self-service" }
    @user.roles << role
    assert_difference("UserRole.count", -1) { @user.destroy }
  end

  test "destroying user destroys dependent notifications" do
    @user.save!
    Notification.create!(
      user: @user,
      title: "Test",
      message: "Test notification",
      notification_type: "system"
    )
    assert_difference("Notification.count", -1) { @user.destroy }
  end
end
