class DigitalSignature < ApplicationRecord
  include TenantScoped
  belongs_to :policy_document
  belongs_to :employee

  # Validations
  validates :status, presence: true, inclusion: { in: %w[signed pending rejected] }
  validates :signature_type, inclusion: { in: %w[electronic digital handwritten pending] }, allow_nil: true
  validates :signed_date, presence: true, if: -> { status == "signed" }

  # Scopes
  scope :signed, -> { where(status: "signed") }
  scope :pending, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :by_policy_document, ->(policy_document_id) { where(policy_document_id: policy_document_id) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :recent, -> { order(signed_date: :desc, created_at: :desc) }

  # Callbacks
  before_save :set_signature_type_if_signed

  # Helper methods
  def signed?
    status == "signed"
  end

  def pending?
    status == "pending"
  end

  def rejected?
    status == "rejected"
  end

  def formatted_signed_date
    signed_date&.strftime("%d/%m/%Y") || "Pending"
  end

  def employee_name
    employee.name
  end

  def document_title
    policy_document.title
  end

  def device_info_display
    device_info.presence || user_agent&.split(" ")&.first || "Unknown"
  end

  private

  def set_signature_type_if_signed
    if status == "signed" && signature_type.blank?
      self.signature_type = "electronic"
    elsif status == "pending" && signature_type.blank?
      self.signature_type = "pending"
    end
  end
end
