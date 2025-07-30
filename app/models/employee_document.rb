class EmployeeDocument < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :name, presence: true
  validates :document_type, presence: true, inclusion: { in: %w[contract id_proof resume certificate other] }
  validates :upload_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active expired pending_review] }
  validates :file_size, presence: true
  validates :uploaded_by, presence: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where(status: 'expired') }
  scope :pending_review, -> { where(status: 'pending_review') }
  scope :by_type, ->(type) { where(document_type: type) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :expiring_soon, -> { where('expiry_date BETWEEN ? AND ?', Date.current, Date.current + 30.days) }
  scope :expired_documents, -> { where('expiry_date < ?', Date.current) }

  # Callbacks
  before_save :check_expiry_status

  # Helper methods
  def active?
    status == 'active'
  end

  def expired?
    status == 'expired'
  end

  def pending_review?
    status == 'pending_review'
  end

  def is_expired?
    expiry_date.present? && expiry_date < Date.current
  end

  def is_expiring_soon?
    expiry_date.present? && expiry_date.between?(Date.current, Date.current + 30.days)
  end

  def days_until_expiry
    return nil unless expiry_date
    (expiry_date - Date.current).to_i
  end

  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def document_type_label
    document_type.titleize
  end

  def formatted_upload_date
    upload_date.strftime('%B %d, %Y')
  end

  def formatted_expiry_date
    expiry_date&.strftime('%B %d, %Y') || 'No expiry'
  end

  def status_color
    case status
    when 'active'
      'green'
    when 'expired'
      'red'
    when 'pending_review'
      'yellow'
    else
      'gray'
    end
  end

  def file_size_formatted
    # Convert bytes to human readable format
    size = file_size.to_i
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / (1024.0 * 1024.0)).round(1)} MB"
    end
  end

  private

  def check_expiry_status
    if expiry_date.present? && expiry_date < Date.current
      self.status = 'expired'
    elsif status == 'expired' && expiry_date.present? && expiry_date >= Date.current
      self.status = 'active'
    end
  end
end
