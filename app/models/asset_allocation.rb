class AssetAllocation < ApplicationRecord
  belongs_to :asset
  belongs_to :employee

  # Validations
  validates :assigned_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active returned] }
  validates :asset_id, uniqueness: { scope: :status, conditions: -> { where(status: 'active') } }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :returned, -> { where(status: 'returned') }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_asset, ->(asset_id) { where(asset_id: asset_id) }
  scope :recent, -> { order(assigned_date: :desc) }

  # Callbacks
  before_create :set_assigned_date
  after_create :update_asset_status
  after_update :update_asset_status_on_return

  # Helper methods
  def active?
    status == 'active'
  end

  def returned?
    status == 'returned'
  end

  def duration_days
    return 0 unless assigned_date
    end_date = return_date || Date.current
    (end_date - assigned_date).to_i
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

  def asset_name
    asset.name
  end

  def asset_serial_number
    asset.serial_number
  end

  def asset_type
    asset.asset_type
  end

  def return_asset(return_date = Date.current, notes = nil)
    update(
      return_date: return_date,
      notes: notes,
      status: 'returned'
    )
  end

  def extend_allocation(new_date, notes = nil)
    return false unless active?
    
    update(
      notes: notes.present? ? "#{self.notes}\nExtended to: #{new_date}" : "Extended to: #{new_date}"
    )
  end

  private

  def set_assigned_date
    self.assigned_date ||= Date.current
  end

  def update_asset_status
    asset.update(status: 'assigned', employee: employee)
  end

  def update_asset_status_on_return
    if status == 'returned'
      asset.update(status: 'available', employee: nil)
    end
  end
end
