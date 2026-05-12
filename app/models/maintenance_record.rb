class MaintenanceRecord < ApplicationRecord
  include BelongsToTenant

  belongs_to :asset

  # Validations
  validates :maintenance_date, presence: true
  validates :maintenance_type, presence: true, inclusion: { in: %w[routine repair upgrade replacement inspection] }
  validates :description, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :performed_by, presence: true

  # Scopes
  scope :by_type, ->(type) { where(maintenance_type: type) }
  scope :recent, -> { order(maintenance_date: :desc) }
  scope :expensive, -> { where("cost > ?", 1000) }
  scope :by_performer, ->(performer) { where(performed_by: performer) }
  scope :this_year, -> { where("maintenance_date >= ?", Date.current.beginning_of_year) }
  scope :last_year, -> { where("maintenance_date >= ? AND maintenance_date < ?", 1.year.ago.beginning_of_year, Date.current.beginning_of_year) }

  # Callbacks
  before_save :set_next_maintenance
  after_save :update_asset_maintenance_dates

  # Helper methods
  def routine?
    maintenance_type == "routine"
  end

  def repair?
    maintenance_type == "repair"
  end

  def upgrade?
    maintenance_type == "upgrade"
  end

  def replacement?
    maintenance_type == "replacement"
  end

  def inspection?
    maintenance_type == "inspection"
  end

  def expensive?
    cost > 1000
  end

  def overdue?
    next_maintenance.present? && next_maintenance < Date.current
  end

  def due_soon?
    next_maintenance.present? && next_maintenance.between?(Date.current, Date.current + 30.days)
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

  def formatted_cost
    "₹#{cost.to_f.round(2)}"
  end

  def formatted_date
    maintenance_date.strftime("%B %d, %Y")
  end

  def formatted_next_maintenance
    next_maintenance&.strftime("%B %d, %Y") || "Not scheduled"
  end

  def maintenance_type_label
    maintenance_type.titleize
  end

  def type_color
    case maintenance_type
    when "routine"
      "green"
    when "repair"
      "orange"
    when "upgrade"
      "blue"
    when "replacement"
      "red"
    when "inspection"
      "purple"
    else
      "gray"
    end
  end

  def cost_category
    case cost
    when 0..100
      "Low"
    when 101..500
      "Medium"
    when 501..1000
      "High"
    else
      "Very High"
    end
  end

  private

  def assign_company_from_current
    self.company_id ||= asset&.company_id || Current.company&.id
  end

  def set_next_maintenance
    return if next_maintenance.present?

    case maintenance_type
    when "routine"
      self.next_maintenance = maintenance_date + 6.months
    when "repair"
      self.next_maintenance = maintenance_date + 3.months
    when "upgrade"
      self.next_maintenance = maintenance_date + 1.year
    when "replacement"
      self.next_maintenance = maintenance_date + 2.years
    when "inspection"
      self.next_maintenance = maintenance_date + 1.month
    end
  end

  def update_asset_maintenance_dates
    asset.update(
      last_maintenance: maintenance_date,
      next_maintenance: next_maintenance
    )
  end
end
