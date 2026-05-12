require "test_helper"

class DigitalSignatureTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @policy_document = PolicyDocument.create!(
      title: "NDA #{SecureRandom.hex(4)}",
      category: "Legal",
      file_path: "/uploads/nda.pdf",
      status: "active",
      file_size: 102_400,
      expiry_date: 1.year.from_now.to_date
    )
    @signature = DigitalSignature.new(
      policy_document: @policy_document,
      employee: @employee,
      status: "pending"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with pending status and no signed_date" do
    assert @signature.valid?
  end

  test "should be valid with signed status and signed_date" do
    @signature.status = "signed"
    @signature.signed_date = Date.current
    assert @signature.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require status" do
    @signature.status = nil
    assert_not @signature.valid?
    assert_includes @signature.errors[:status], "can't be blank"
  end

  test "should require signed_date when status is signed" do
    @signature.status = "signed"
    @signature.signed_date = nil
    assert_not @signature.valid?
    assert_includes @signature.errors[:signed_date], "can't be blank"
  end

  test "should not require signed_date when status is pending" do
    @signature.status = "pending"
    @signature.signed_date = nil
    assert @signature.valid?
  end

  test "should not require signed_date when status is rejected" do
    @signature.status = "rejected"
    @signature.signed_date = nil
    assert @signature.valid?
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @signature.status = "approved"
    assert_not @signature.valid?
    assert_includes @signature.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[signed pending rejected].each do |s|
      @signature.status = s
      @signature.signed_date = (s == "signed" ? Date.current : nil)
      assert @signature.valid?, "#{s} should be valid"
    end
  end

  test "should reject invalid signature_type" do
    @signature.signature_type = "biometric"
    assert_not @signature.valid?
    assert_includes @signature.errors[:signature_type], "is not included in the list"
  end

  test "should accept all valid signature_types" do
    %w[electronic digital handwritten pending].each do |t|
      @signature.signature_type = t
      assert @signature.valid?, "#{t} should be valid"
    end
  end

  test "should allow nil signature_type" do
    @signature.signature_type = nil
    assert @signature.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to policy_document" do
    assert_respond_to @signature, :policy_document
  end

  test "should belong to employee" do
    assert_respond_to @signature, :employee
  end

  test "should require policy_document" do
    @signature.policy_document = nil
    assert_not @signature.valid?
  end

  test "should require employee" do
    @signature.employee = nil
    assert_not @signature.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "signed scope returns signed signatures" do
    @signature.status = "signed"
    @signature.signed_date = Date.current
    @signature.save!
    assert_includes DigitalSignature.signed, @signature
  end

  test "pending scope returns pending signatures" do
    @signature.status = "pending"
    @signature.save!
    assert_includes DigitalSignature.pending, @signature
  end

  test "rejected scope returns rejected signatures" do
    @signature.status = "rejected"
    @signature.save!
    assert_includes DigitalSignature.rejected, @signature
  end

  test "by_policy_document scope filters by policy_document_id" do
    @signature.save!
    assert_includes DigitalSignature.by_policy_document(@policy_document.id), @signature
  end

  test "by_employee scope filters by employee_id" do
    @signature.save!
    assert_includes DigitalSignature.by_employee(@employee.id), @signature
  end

  # ── Callback: set_signature_type_if_signed ────────────────────────────────
  test "sets signature_type to electronic when signed without a type" do
    @signature.status = "signed"
    @signature.signed_date = Date.current
    @signature.signature_type = nil
    @signature.save!
    assert_equal "electronic", @signature.reload.signature_type
  end

  test "sets signature_type to pending when pending without a type" do
    @signature.status = "pending"
    @signature.signature_type = nil
    @signature.save!
    assert_equal "pending", @signature.reload.signature_type
  end

  test "does not override explicit signature_type" do
    @signature.status = "signed"
    @signature.signed_date = Date.current
    @signature.signature_type = "handwritten"
    @signature.save!
    assert_equal "handwritten", @signature.reload.signature_type
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "signed? returns true when status is signed" do
    @signature.status = "signed"
    assert @signature.signed?
  end

  test "pending? returns true when status is pending" do
    @signature.status = "pending"
    assert @signature.pending?
  end

  test "rejected? returns true when status is rejected" do
    @signature.status = "rejected"
    assert @signature.rejected?
  end

  test "formatted_signed_date returns formatted date when set" do
    @signature.signed_date = Date.new(2024, 6, 15)
    assert_equal "15/06/2024", @signature.formatted_signed_date
  end

  test "formatted_signed_date returns Pending when signed_date is nil" do
    @signature.signed_date = nil
    assert_equal "Pending", @signature.formatted_signed_date
  end

  test "employee_name delegates to employee" do
    assert_equal @employee.name, @signature.employee_name
  end

  test "document_title delegates to policy_document" do
    assert_equal @policy_document.title, @signature.document_title
  end

  test "device_info_display returns device_info when present" do
    @signature.device_info = "MacBook Pro"
    assert_equal "MacBook Pro", @signature.device_info_display
  end

  test "device_info_display returns first user_agent token when device_info is blank" do
    @signature.device_info = nil
    @signature.user_agent = "Mozilla/5.0 Chrome/120"
    assert_equal "Mozilla/5.0", @signature.device_info_display
  end

  test "device_info_display returns Unknown when both are blank" do
    @signature.device_info = nil
    @signature.user_agent = nil
    assert_equal "Unknown", @signature.device_info_display
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create digital signature" do
    assert_difference("DigitalSignature.count") { @signature.save! }
  end

  test "should update digital signature status to signed" do
    @signature.save!
    @signature.update!(status: "signed", signed_date: Date.current)
    assert_equal "signed", @signature.reload.status
    assert_not_nil @signature.reload.signed_date
  end

  test "should destroy digital signature" do
    @signature.save!
    assert_difference("DigitalSignature.count", -1) { @signature.destroy }
  end
end
