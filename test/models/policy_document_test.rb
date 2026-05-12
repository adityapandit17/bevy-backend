require "test_helper"

class PolicyDocumentTest < ActiveSupport::TestCase
  def setup
    @document = PolicyDocument.new(
      title: "Employee Code of Conduct",
      category: "HR Policies",
      file_path: "/uploads/policies/code_of_conduct.pdf",
      status: "active",
      file_size: 512_000,
      expiry_date: 1.year.from_now.to_date
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @document.valid?
  end

  test "should be valid without uploader" do
    @document.uploaded_by = nil
    assert @document.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @document.title = nil
    assert_not @document.valid?
    assert_includes @document.errors[:title], "can't be blank"
  end

  test "should require category" do
    @document.category = nil
    assert_not @document.valid?
    assert_includes @document.errors[:category], "can't be blank"
  end

  test "should require file_path" do
    @document.file_path = nil
    assert_not @document.valid?
    assert_includes @document.errors[:file_path], "can't be blank"
  end

  test "should require status" do
    @document.status = nil
    assert_not @document.valid?
    assert_includes @document.errors[:status], "can't be blank"
  end

  test "should require file_size" do
    @document.file_size = nil
    assert_not @document.valid?
    assert_includes @document.errors[:file_size], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @document.status = "archived"
    assert_not @document.valid?
    assert_includes @document.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[active expired expiring].each do |s|
      @document.status = s
      assert @document.valid?, "#{s} should be valid"
    end
  end

  # ── Numericality validations ──────────────────────────────────────────────
  test "should reject negative file_size" do
    @document.file_size = -1
    assert_not @document.valid?
  end

  test "should accept zero file_size" do
    @document.file_size = 0
    assert @document.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should optionally belong to uploader" do
    assert_respond_to @document, :uploader
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active documents" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    assert_includes PolicyDocument.active, @document
  end

  test "expired scope returns expired documents" do
    @document.expiry_date = nil
    @document.status = "expired"
    @document.save!
    assert_includes PolicyDocument.expired, @document
  end

  test "expiring scope returns expiring documents" do
    @document.expiry_date = nil
    @document.status = "expiring"
    @document.save!
    assert_includes PolicyDocument.expiring, @document
  end

  test "by_category scope filters by category" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    assert_includes PolicyDocument.by_category("HR Policies"), @document
  end

  test "expiring_soon scope returns documents expiring within 30 days" do
    @document.expiry_date = 15.days.from_now.to_date
    @document.save!
    assert_includes PolicyDocument.expiring_soon, @document
  end

  test "expiring_soon scope does not include documents expiring beyond 30 days" do
    @document.expiry_date = 60.days.from_now.to_date
    @document.save!
    assert_not_includes PolicyDocument.expiring_soon, @document
  end

  test "expired_documents scope returns documents with past expiry_date" do
    @document.expiry_date = 1.day.ago.to_date
    @document.save!
    assert_includes PolicyDocument.expired_documents, @document
  end

  # ── Callback: check_expiry_status ─────────────────────────────────────────
  test "sets status to expired when expiry_date is in the past" do
    @document.expiry_date = 1.day.ago.to_date
    @document.status = "active"
    @document.save!
    assert_equal "expired", @document.reload.status
  end

  test "sets status to expiring when expiry_date is within 30 days" do
    @document.expiry_date = 15.days.from_now.to_date
    @document.status = "active"
    @document.save!
    assert_equal "expiring", @document.reload.status
  end

  test "sets status to active when expiry_date is beyond 30 days" do
    @document.expiry_date = 60.days.from_now.to_date
    @document.status = "expiring"
    @document.save!
    assert_equal "active", @document.reload.status
  end

  test "does not change status when no expiry_date" do
    @document.expiry_date = nil
    @document.status = "active"
    @document.save!
    assert_equal "active", @document.reload.status
  end

  # ── Callback: update_last_updated ─────────────────────────────────────────
  test "update_last_updated sets last_updated on save" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    assert_not_nil @document.reload.last_updated
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "active? returns true when status is active" do
    @document.status = "active"
    assert @document.active?
  end

  test "expired? returns true when status is expired" do
    @document.status = "expired"
    assert @document.expired?
  end

  test "expiring? returns true when status is expiring" do
    @document.status = "expiring"
    assert @document.expiring?
  end

  test "is_expired? returns true when expiry_date is in the past" do
    @document.expiry_date = 1.day.ago.to_date
    assert @document.is_expired?
  end

  test "is_expired? returns false when expiry_date is in the future" do
    @document.expiry_date = 1.day.from_now.to_date
    assert_not @document.is_expired?
  end

  test "is_expiring_soon? returns true when expiry within 30 days" do
    @document.expiry_date = 20.days.from_now.to_date
    assert @document.is_expiring_soon?
  end

  test "is_expiring_soon? returns false when expiry beyond 30 days" do
    @document.expiry_date = 45.days.from_now.to_date
    assert_not @document.is_expiring_soon?
  end

  test "days_until_expiry returns positive integer for future expiry" do
    @document.expiry_date = 30.days.from_now.to_date
    assert @document.days_until_expiry > 0
  end

  test "days_until_expiry returns nil when expiry_date is nil" do
    @document.expiry_date = nil
    assert_nil @document.days_until_expiry
  end

  test "formatted_expiry_date returns formatted date string" do
    @document.expiry_date = Date.new(2025, 12, 31)
    assert_equal "31/12/2025", @document.formatted_expiry_date
  end

  test "formatted_expiry_date returns No expiry when nil" do
    @document.expiry_date = nil
    assert_equal "No expiry", @document.formatted_expiry_date
  end

  test "file_size_formatted returns bytes for small files" do
    @document.file_size = 500
    assert_equal "500 B", @document.file_size_formatted
  end

  test "file_size_formatted returns KB for medium files" do
    @document.file_size = 204_800
    assert_equal "200.0 KB", @document.file_size_formatted
  end

  test "file_size_formatted returns MB for large files" do
    @document.file_size = 2 * 1024 * 1024
    assert_equal "2.0 MB", @document.file_size_formatted
  end

  test "increment_downloads! increments the downloads counter" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    before = @document.downloads.to_i
    @document.increment_downloads!
    assert_equal before + 1, @document.reload.downloads
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create policy document" do
    @document.expiry_date = 1.year.from_now.to_date
    assert_difference("PolicyDocument.count") { @document.save! }
  end

  test "should update policy document title" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    @document.update!(title: "Updated Policy")
    assert_equal "Updated Policy", @document.reload.title
  end

  test "should destroy policy document" do
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    assert_difference("PolicyDocument.count", -1) { @document.destroy }
  end
end
