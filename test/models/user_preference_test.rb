require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  def setup
    # Create a unique user to avoid fixture conflicts
    @user = User.create!(
      first_name: "Pref",
      last_name: "User#{SecureRandom.hex(4)}",
      email: "pref.user.#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      status: "active"
    )
    @preference = UserPreference.new(
      user: @user,
      language: "en",
      timezone: "UTC",
      date_format: "MM/DD/YYYY",
      theme: "light",
      email_notifications: true,
      push_notifications: true
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @preference.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require timezone" do
    @preference.timezone = nil
    assert_not @preference.valid?
    assert_includes @preference.errors[:timezone], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid language" do
    @preference.language = "jp"
    assert_not @preference.valid?
    assert_includes @preference.errors[:language], "is not included in the list"
  end

  test "should accept all valid languages" do
    %w[en es fr de].each do |lang|
      @preference.language = lang
      assert @preference.valid?, "#{lang} should be valid"
    end
  end

  test "should allow nil language" do
    @preference.language = nil
    assert @preference.valid?
  end

  test "should reject invalid date_format" do
    @preference.date_format = "YYYY/DD/MM"
    assert_not @preference.valid?
    assert_includes @preference.errors[:date_format], "is not included in the list"
  end

  test "should accept all valid date_formats" do
    ["MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD", "DD MMM YYYY"].each do |fmt|
      @preference.date_format = fmt
      assert @preference.valid?, "#{fmt} should be valid"
    end
  end

  test "should allow nil date_format" do
    @preference.date_format = nil
    assert @preference.valid?
  end

  test "should reject invalid theme" do
    @preference.theme = "pink"
    assert_not @preference.valid?
    assert_includes @preference.errors[:theme], "is not included in the list"
  end

  test "should accept all valid themes" do
    %w[light dark system].each do |t|
      @preference.theme = t
      assert @preference.valid?, "#{t} should be valid"
    end
  end

  test "should allow nil theme" do
    @preference.theme = nil
    assert @preference.valid?
  end

  # ── Uniqueness ────────────────────────────────────────────────────────────
  test "should enforce one preference per user" do
    @preference.save!
    dup = UserPreference.new(user: @user, timezone: "Asia/Kolkata")
    assert_not dup.valid?
    assert dup.errors[:user_id].any?
  end

  test "should allow preferences for different users" do
    @preference.save!
    other_user = User.create!(
      first_name: "Other",
      last_name: "User#{SecureRandom.hex(4)}",
      email: "other.#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      status: "active"
    )
    other = UserPreference.new(user: other_user, timezone: "UTC")
    assert other.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to user" do
    assert_respond_to @preference, :user
  end

  test "should require user" do
    @preference.user = nil
    assert_not @preference.valid?
  end

  # ── Class methods ─────────────────────────────────────────────────────────
  test "for_user returns existing preference" do
    @preference.save!
    found = UserPreference.for_user(@user)
    assert_equal @preference, found
  end

  test "for_user creates preference with defaults when none exists" do
    assert_difference("UserPreference.count") do
      pref = UserPreference.for_user(@user)
      assert_equal "en", pref.language
      assert_equal "UTC", pref.timezone
      assert_equal "MM/DD/YYYY", pref.date_format
      assert_equal "light", pref.theme
      assert pref.email_notifications
      assert pref.push_notifications
      assert pref.leave_notifications
      assert pref.attendance_notifications
      assert_not pref.payroll_notifications
      assert pref.system_notifications
    end
  end

  test "for_user is idempotent — does not create duplicate" do
    @preference.save!
    assert_no_difference("UserPreference.count") { UserPreference.for_user(@user) }
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create user preference" do
    assert_difference("UserPreference.count") { @preference.save! }
  end

  test "should update user preference" do
    @preference.save!
    @preference.update!(theme: "dark")
    assert_equal "dark", @preference.reload.theme
  end

  test "should destroy user preference" do
    @preference.save!
    assert_difference("UserPreference.count", -1) { @preference.destroy }
  end
end
