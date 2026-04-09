class Company < ApplicationRecord
  # Note: These associations would need company_id fields in the respective tables
  # For now, we'll keep the model simple without these associations
  # has_many :departments, dependent: :destroy
  # has_many :employees, through: :departments
  # has_many :job_openings, through: :departments
  # has_many :assets, dependent: :destroy
  # has_many :asset_allocations, through: :assets
  # has_many :onboarding_employees, dependent: :destroy
  # has_many :offboarding_employees, dependent: :destroy
  # has_many :candidates, dependent: :destroy
  # has_many :interviews, through: :candidates

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, uniqueness: true, length: { minimum: 2, maximum: 10 }
  validates :industry, presence: true
  validates :employee_count, presence: true
  validates :timezone, presence: true
  validates :currency, presence: true, length: { is: 3 }
  validates :country_code, allow_nil: true, allow_blank: true, length: { is: 2 }

  scope :by_industry, ->(industry) { where(industry: industry) }
  scope :large_companies, -> { where("CAST(employee_count AS INTEGER) > ?", 1000) }
  scope :small_companies, -> { where("CAST(employee_count AS INTEGER) <= ?", 100) }

  def formatted_employee_count
    "#{employee_count} employees"
  end

  def display_name
    "#{name} (#{code})"
  end
end
