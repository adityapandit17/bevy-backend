require "test_helper"

class EmployeeDocumentTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @document = EmployeeDocument.new(
      employee: @employee,
      name: "Employment Contract 2024",
      document_type: "contract",
      upload_date: Date.current,
      status: "active",
      file_size: 204800,
      uploaded_by: "HR Manager",
      expiry_date: 1.year.from_now.to_date
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @document.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require name" do
    @document.name = nil
    assert_not @document.valid?
    assert_includes @document.errors[:name], "can't be blank"
  end

  test "should require document_type" do
    @document.document_type = nil
    assert_not @document.valid?
    assert_includes @document.errors[:document_type], "can't be blank"
  end

  test "should require upload_date" do
    @document.upload_date = nil
    assert_not @document.valid?
    assert_includes @document.errors[:upload_date], "can't be blank"
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

  test "should require uploaded_by" do
    @document.uploaded_by = nil
    assert_not @document.valid?
    assert_includes @document.errors[:uploaded_by], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid document_type" do
    @document.document_type = "passport"
    assert_not @document.valid?
    assert_includes @document.errors[:document_type], "is not included in the list"
  end

  test "should accept all valid document_types" do
    %w[contract id_proof resume certificate other].each do |type|
      @document.document_type = type
      assert @document.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid status" do
    @document.status = "deleted"
    assert_not @document.valid?
    assert_includes @document.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[active expired pending_review].each do |s|
      @document.status = s
      assert @document.valid?, "#{s} should be valid"
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @document, :employee
  end

  test "should require employee" do
    @document.employee = nil
    assert_not @document.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "active scope returns active documents" do
    @document.status = "active"
    @document.save!
    expired = EmployeeDocument.create!(
      employee: employees(:two),
      name: "Old Contract",
      document_type: "contract",
      upload_date: 2.years.ago.to_date,
      status: "expired",
      file_size: 1024,
      uploaded_by: "HR"
    )
    assert_includes EmployeeDocument.active, @document
    assert_not_includes EmployeeDocument.active, expired
  end

  test "expired scope returns expired documents" do
    @document.status = "expired"
    @document.save!
    assert_includes EmployeeDocument.expired, @document
  end

  test "by_type scope filters by document_type" do
    @document.document_type = "certificate"
    @document.save!
    assert_includes EmployeeDocument.by_type("certificate"), @document
  end

  test "by_employee scope filters by employee_id" do
    @document.save!
    assert_includes EmployeeDocument.by_employee(@employee.id), @document
  end

  test "expiring_soon scope returns documents expiring within 30 days" do
    @document.expiry_date = 15.days.from_now.to_date
    @document.save!
    assert_includes EmployeeDocument.expiring_soon, @document
  end

  # ── Callback: auto-expire based on expiry_date ────────────────────────────
  test "sets status to expired when expiry_date is in the past" do
    @document.expiry_date = 1.day.ago.to_date
    @document.status = "active"
    @document.save!
    assert_equal "expired", @document.reload.status
  end

  test "reinstates active status when expiry_date set to future" do
    @document.status = "expired"
    @document.expiry_date = 1.year.from_now.to_date
    @document.save!
    assert_equal "active", @document.reload.status
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

  test "pending_review? returns true when status is pending_review" do
    @document.status = "pending_review"
    assert @document.pending_review?
  end

  test "is_expired? returns true when expiry_date is in the past" do
    @document.expiry_date = 1.day.ago.to_date
    assert @document.is_expired?
  end

  test "is_expiring_soon? returns true when expiry within 30 days" do
    @document.expiry_date = 20.days.from_now.to_date
    assert @document.is_expiring_soon?
  end

  test "days_until_expiry returns positive integer for future expiry" do
    @document.expiry_date = 30.days.from_now.to_date
    assert @document.days_until_expiry > 0
  end

  test "days_until_expiry returns nil when no expiry_date" do
    @document.expiry_date = nil
    assert_nil @document.days_until_expiry
  end

  test "file_size_formatted returns human-readable size in KB" do
    @document.file_size = 204800
    assert_equal "200.0 KB", @document.file_size_formatted
  end

  test "file_size_formatted returns MB for large files" do
    @document.file_size = 2 * 1024 * 1024
    assert_equal "2.0 MB", @document.file_size_formatted
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @document.employee_name
  end

  test "document_type_label returns titleized type" do
    @document.document_type = "id_proof"
    assert_equal "Id Proof", @document.document_type_label
  end

  test "formatted_upload_date returns readable date" do
    @document.upload_date = Date.new(2024, 6, 15)
    assert_equal "June 15, 2024", @document.formatted_upload_date
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create employee document" do
    assert_difference("EmployeeDocument.count") { @document.save! }
  end

  test "should update employee document" do
    @document.save!
    @document.update!(name: "Updated Contract")
    assert_equal "Updated Contract", @document.reload.name
  end

  test "should destroy employee document" do
    @document.save!
    assert_difference("EmployeeDocument.count", -1) { @document.destroy }
  end
end
