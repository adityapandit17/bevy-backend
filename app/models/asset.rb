class Asset < ApplicationRecord
  include TenantScoped
  belongs_to :employee, optional: true
  has_many :asset_allocations, dependent: :destroy
  has_many :maintenance_records, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: %w[laptop desktop mobile printer server network other] }
  validates :serial_number, presence: true, uniqueness: true
  validates :asset_tag, presence: true, uniqueness: true
  validates :brand, presence: true
  validates :model, presence: true
  validates :purchase_date, presence: true
  validates :purchase_cost, presence: true, numericality: { greater_than: 0 }
  validates :current_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[available assigned maintenance retired lost] }
  validates :location, presence: true
  validates :department, presence: true
  validates :condition, presence: true, inclusion: { in: %w[excellent good fair poor] }

  # Scopes
  scope :available, -> { where(status: "available") }
  scope :assigned, -> { where(status: "assigned") }
  scope :maintenance, -> { where(status: "maintenance") }
  scope :retired, -> { where(status: "retired") }
  scope :lost, -> { where(status: "lost") }
  scope :by_type, ->(type) { where(asset_type: type) }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_condition, ->(cond) { where(condition: cond) }
  scope :overdue_maintenance, -> { where("next_maintenance < ?", Date.current) }
  scope :due_maintenance_soon, -> { where("next_maintenance BETWEEN ? AND ?", Date.current, Date.current + 30.days) }
  scope :warranty_expiring_soon, -> { where("warranty_expiry BETWEEN ? AND ?", Date.current, Date.current + 90.days) }

  # Callbacks
  before_validation :ensure_asset_tag, on: :create
  before_save :calculate_depreciation
  before_save :update_status_based_on_allocation

  # Helper methods
  def assigned?
    status == "assigned" && employee.present?
  end

  def available?
    status == "available"
  end

  def under_maintenance?
    status == "maintenance"
  end

  def retired?
    status == "retired"
  end

  def lost?
    status == "lost"
  end

  def overdue_maintenance?
    next_maintenance.present? && next_maintenance < Date.current
  end

  def due_maintenance_soon?
    next_maintenance.present? && next_maintenance.between?(Date.current, Date.current + 30.days)
  end

  def warranty_expiring_soon?
    warranty_expiry.present? && warranty_expiry.between?(Date.current, Date.current + 90.days)
  end

  def warranty_expired?
    warranty_expiry.present? && warranty_expiry < Date.current
  end

  def age_in_years
    return 0 unless purchase_date

    ((Date.current - purchase_date) / 365.25).to_i
  end

  def depreciation_rate
    case asset_type
    when "laptop", "desktop"
      0.25 # 25% per year
    when "mobile"
      0.40 # 40% per year
    when "printer"
      0.20 # 20% per year
    when "server", "network"
      0.15 # 15% per year
    else
      0.20 # 20% per year default
    end
  end

  def total_maintenance_cost
    maintenance_records.sum(:cost)
  end

  def last_maintenance_record
    maintenance_records.order(maintenance_date: :desc).first
  end

  def current_allocation
    asset_allocations.where(status: "active").first
  end

  def allocation_history
    asset_allocations.order(assigned_date: :desc)
  end

  def employee_name
    employee&.name || "Not assigned"
  end

  def employee_email
    employee&.email
  end

  def employee_department
    employee&.department&.name || department
  end

  def full_name
    "#{brand} #{model} - #{serial_number}"
  end

  def scan_payload
    AssetLabelService::SCAN_PREFIX + asset_tag.to_s
  end

  def self.find_by_scan_code(code)
    normalized = code.to_s.strip
    return nil if normalized.blank?

    if (match = normalized.match(/\ABEVYHR[\|:]AST[\|:](.+)\z/i))
      normalized = match[1].strip
    end

    find_by(asset_tag: normalized) ||
      find_by(serial_number: normalized) ||
      (normalized.match?(/\A\d+\z/) ? find_by(id: normalized.to_i) : nil)
  end

  def status_color
    case status
    when "available"
      "green"
    when "assigned"
      "blue"
    when "maintenance"
      "orange"
    when "retired"
      "gray"
    when "lost"
      "red"
    else
      "gray"
    end
  end

  def condition_color
    case condition
    when "excellent"
      "green"
    when "good"
      "blue"
    when "fair"
      "yellow"
    when "poor"
      "red"
    else
      "gray"
    end
  end

  private

  def ensure_asset_tag
    return if asset_tag.present?

    loop do
      candidate = format("AST-%s-%s", company_id, SecureRandom.alphanumeric(8).upcase)
      unless self.class.exists?(asset_tag: candidate)
        self.asset_tag = candidate
        break
      end
    end
  end

  def calculate_depreciation
    return unless purchase_date && purchase_cost

    years_old = age_in_years
    depreciation_factor = (1 - depreciation_rate) ** years_old
    self.current_value = (purchase_cost * depreciation_factor).round(2)
  end

  def update_status_based_on_allocation
    if employee.present?
      self.status = "assigned"
    elsif status == "assigned"
      self.status = "available"
    end
  end
end
