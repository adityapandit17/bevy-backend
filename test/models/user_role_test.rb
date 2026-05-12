require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @role = Role.find_or_create_by!(name: "URTestRole#{SecureRandom.hex(4)}") do |r|
      r.description = "test"
    end
    @user_role = UserRole.new(user: @user, role: @role)
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @user_role.valid?
  end

  # ── Presence / association validations ───────────────────────────────────
  test "should require user" do
    @user_role.user = nil
    assert_not @user_role.valid?
  end

  test "should require role" do
    @user_role.role = nil
    assert_not @user_role.valid?
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce unique user_id + role_id" do
    @user_role.save!
    dup = UserRole.new(user: @user, role: @role)
    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "should allow same role for different users" do
    @user_role.save!
    other_user = users(:two)
    other_ur = UserRole.new(user: other_user, role: @role)
    assert other_ur.valid?
  end

  test "should allow same user with different roles" do
    @user_role.save!
    other_role = Role.create!(name: "AnotherURRole#{SecureRandom.hex(4)}", description: "other")
    other_ur = UserRole.new(user: @user, role: other_role)
    assert other_ur.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to user" do
    assert_respond_to @user_role, :user
  end

  test "should belong to role" do
    assert_respond_to @user_role, :role
  end

  # ── Integration with User#has_role? ──────────────────────────────────────
  test "adding user_role makes has_role? return true" do
    @user_role.save!
    assert @user.has_role?(@role.name)
  end

  test "removing user_role makes has_role? return false" do
    @user_role.save!
    @user_role.destroy
    @user.reload
    assert_not @user.has_role?(@role.name)
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create user_role" do
    assert_difference("UserRole.count") { @user_role.save! }
  end

  test "should destroy user_role" do
    @user_role.save!
    assert_difference("UserRole.count", -1) { @user_role.destroy }
  end
end
