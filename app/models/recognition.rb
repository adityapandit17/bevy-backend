class Recognition < ApplicationRecord
  include TenantScoped
  belongs_to :given_by, class_name: "User", foreign_key: :given_by_id
  belongs_to :received_by, class_name: "Employee", foreign_key: :received_by_id

  # Validations
  validates :title, presence: true
  validates :recognition_type, presence: true, inclusion: { in: %w[appreciation achievement milestone excellence teamwork innovation leadership] }
  validates :status, inclusion: { in: %w[active archived] }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }
  scope :by_type, ->(type) { where(recognition_type: type) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_employee, ->(employee_id) { where(received_by_id: employee_id) }
  scope :by_giver, ->(user_id) { where(given_by_id: user_id) }

  # Class methods
  def self.categories
    %w[performance teamwork innovation leadership customer_service project_success other]
  end

  def self.types
    %w[appreciation achievement milestone excellence teamwork innovation leadership]
  end

  # Instance methods
  def formatted_date
    created_at&.strftime("%B %d, %Y")
  end

  def given_by_name
    given_by&.name || "Unknown"
  end

  def received_by_name
    received_by ? "#{received_by.first_name} #{received_by.last_name}" : "Unknown"
  end
end
