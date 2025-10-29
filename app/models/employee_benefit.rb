class EmployeeBenefit < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :name, presence: true
  validates :benefit_type, presence: true, inclusion: { in: %w[health_insurance life_insurance dental_insurance vision_insurance retirement wellness other] }
  validates :provider, presence: true
  validates :coverage, presence: true
  validates :start_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive pending expired] }
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_type, ->(type) { where(benefit_type: type) }
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :pending, -> { where(status: "pending") }
  scope :expired, -> { where(status: "expired") }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :expiring_soon, -> { where("end_date BETWEEN ? AND ?", Date.current, Date.current + 30.days) }
  scope :expired_benefits, -> { where("end_date < ?", Date.current) }

  # Callbacks
  before_save :check_expiry_status

  # Helper methods
  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end

  def pending?
    status == "pending"
  end

  def expired?
    status == "expired"
  end

  def is_expired?
    end_date.present? && end_date < Date.current
  end

  def is_expiring_soon?
    end_date.present? && end_date.between?(Date.current, Date.current + 30.days)
  end

  def days_until_expiry
    return nil unless end_date

    (end_date - Date.current).to_i
  end

  def days_since_start
    (Date.current - start_date).to_i
  end

  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def employee_department
    employee.department&.name
  end

  def benefit_type_label
    benefit_type.titleize
  end

  def formatted_start_date
    start_date.strftime("%B %d, %Y")
  end

  def formatted_end_date
    end_date&.strftime("%B %d, %Y") || "No end date"
  end

  def status_color
    case status
    when "active"
      "green"
    when "inactive"
      "gray"
    when "pending"
      "yellow"
    when "expired"
      "red"
    else
      "gray"
    end
  end

  def status_label
    status.titleize
  end

  def cost_formatted
    "₹#{cost.to_f.round(2)}"
  end

  def annual_cost
    cost * 12
  end

  def annual_cost_formatted
    "₹#{annual_cost.to_f.round(2)}"
  end

  def coverage_summary
    "#{coverage} - #{provider}"
  end

  def duration_summary
    if end_date.present?
      days = (end_date - start_date).to_i
      "#{formatted_start_date} to #{formatted_end_date} (#{days} days)"
    else
      "Started #{formatted_start_date} (Ongoing)"
    end
  end

  def benefit_icon
    case benefit_type
    when "health_insurance"
      "🏥"
    when "life_insurance"
      "🛡️"
    when "dental_insurance"
      "🦷"
    when "vision_insurance"
      "👁️"
    when "retirement"
      "💰"
    when "wellness"
      "💪"
    else
      "🎁"
    end
  end

  def can_edit?
    active? || pending?
  end

  def can_cancel?
    active? && end_date.present? && end_date > Date.current
  end

  private

  def check_expiry_status
    if end_date.present? && end_date < Date.current
      self.status = "expired"
    elsif status == "expired" && end_date.present? && end_date >= Date.current
      self.status = "active"
    end
  end
end
