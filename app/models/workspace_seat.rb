# frozen_string_literal: true

class WorkspaceSeat < ApplicationRecord
  include TenantScoped

  belongs_to :employee, optional: true

  STATUSES = %w[occupied vacant blocked].freeze
  ZONES = %w[north center south].freeze

  validates :label, presence: true, uniqueness: { scope: :company_id }
  validates :zone, presence: true, inclusion: { in: ZONES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :by_zone, ->(zone) { where(zone: zone) if zone.present? && zone != "all" }

  def employee_name
    employee&.name
  end

  def employee_department
    employee&.department&.name
  end
end
