class Department < ApplicationRecord
  include BelongsToTenant

  has_many :employees, dependent: :restrict_with_error
  has_many :job_openings, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :company_id }
end
