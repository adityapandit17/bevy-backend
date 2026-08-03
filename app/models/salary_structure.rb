class SalaryStructure < ApplicationRecord
  include TenantScoped
  belongs_to :employee
  belongs_to :created_by, class_name: "User", optional: true, foreign_key: :created_by_id

  REVISION_TYPES = %w[joining appraisal promotion correction adjustment].freeze

  # Validations
  validates :effective_from, presence: true, if: -> { persisted? || effective_from.present? }
  validates :revision_type, inclusion: { in: REVISION_TYPES }, allow_nil: false
  validate :no_overlapping_periods

  scope :chronological, -> { order(effective_from: :asc, created_at: :asc) }
  scope :recent, -> { order(effective_from: :desc, created_at: :desc) }

  # Before save, ensure allowances contains the sum of other allowances + bonus
  # This ensures the database always stores the combined value
  before_validation :assign_default_revision_type, on: :create
  before_validation :close_previous_open_structures, on: :create
  before_validation :capture_previous_annual_ctc, on: :create
  before_save :combine_allowances_and_bonus
  before_save :calculate_monthly_ctc

  # Active structure for a date (defaults to today)
  def self.current_for(employee, on: Date.current)
    return nil unless employee

    on = on.is_a?(String) ? Date.parse(on) : on
    employee.salary_structures
            .where("effective_from <= ?", on)
            .where("effective_upto IS NULL OR effective_upto >= ?", on)
            .order(effective_from: :desc, created_at: :desc)
            .first
  end

  # Ordered appraisal / compensation history with deltas for profile UI
  def self.appraisal_history_for(employee)
    structures = employee.salary_structures.recent.to_a
    structures.map.with_index do |structure, index|
      # Chronologically previous = next item in desc-ordered list
      previous = structures[index + 1]
      structure.history_payload(previous: previous)
    end
  end

  def history_payload(previous: nil)
    prev_ctc = previous_annual_ctc.presence || previous&.annual_ctc
    current_ctc = annual_ctc.to_f
    prev_ctc_f = prev_ctc.to_f
    change_amount = prev_ctc.present? ? (current_ctc - prev_ctc_f).round(2) : nil
    change_percent =
      if prev_ctc.present? && prev_ctc_f.positive?
        (((current_ctc - prev_ctc_f) / prev_ctc_f) * 100).round(2)
      end

    {
      id: id,
      revision_type: revision_type,
      revision_type_label: revision_type.to_s.humanize,
      effective_from: effective_from,
      effective_upto: effective_upto,
      basic: basic.to_f,
      hra: hra.to_f,
      allowances: allowances.to_f,
      annual_ctc: current_ctc,
      monthly_ctc: monthly_ctc.to_f,
      previous_annual_ctc: prev_ctc.present? ? prev_ctc_f : nil,
      change_amount: change_amount,
      change_percent: change_percent,
      notes: notes,
      level: level,
      created_by: created_by&.name,
      created_at: created_at
    }
  end

  def current?(on: Date.current)
    return false unless effective_from
    return false if effective_from > on
    return true if effective_upto.nil?

    effective_upto >= on
  end

  # Check if two date ranges overlap
  # Two periods [from_A, upto_A] and [from_B, upto_B] overlap if:
  # from_B <= upto_A AND from_A <= upto_B
  # If upto is nil, it means indefinite (ongoing), so it overlaps with any period that starts on or after from
  def self.periods_overlap?(from1, upto1, from2, upto2)
    return false unless from1 && from2

    # Convert to dates if strings
    from1 = from1.is_a?(String) ? Date.parse(from1) : from1
    from2 = from2.is_a?(String) ? Date.parse(from2) : from2
    upto1 = upto1.is_a?(String) ? Date.parse(upto1) : upto1 if upto1
    upto2 = upto2.is_a?(String) ? Date.parse(upto2) : upto2 if upto2

    # If either period has no end date (indefinite), check if they overlap
    if upto1.nil? && upto2.nil?
      # Both are indefinite - they overlap if they start on the same date or if one starts before the other
      true
    elsif upto1.nil?
      # First period is indefinite - overlaps if from1 <= upto2
      from1 <= upto2
    elsif upto2.nil?
      # Second period is indefinite - overlaps if from2 <= upto1
      from2 <= upto1
    else
      # Both have end dates - standard overlap check
      from2 <= upto1 && from1 <= upto2
    end
  end

  private

  def assign_default_revision_type
    self.revision_type = revision_type.presence || "appraisal"
    return if employee.blank?

    if employee.salary_structures.where.not(id: id || 0).none?
      self.revision_type = "joining" if revision_type == "appraisal"
    end
  end

  # When adding a new structure that starts after an open-ended one, close the prior period
  # so history stays contiguous without manual overlap fixes.
  def close_previous_open_structures
    return unless employee_id && effective_from

    new_from = effective_from.is_a?(String) ? Date.parse(effective_from) : effective_from
    open_structures = employee.salary_structures
                              .where.not(id: id || 0)
                              .where(effective_upto: nil)
                              .where("effective_from < ?", new_from)

    open_structures.find_each do |prior|
      prior.update_columns(effective_upto: new_from - 1.day, updated_at: Time.current)
    end
  end

  def capture_previous_annual_ctc
    return if previous_annual_ctc.present?
    return unless employee_id && effective_from

    new_from = effective_from.is_a?(String) ? Date.parse(effective_from) : effective_from
    previous = employee.salary_structures
                       .where.not(id: id || 0)
                       .where("effective_from < ?", new_from)
                       .order(effective_from: :desc, created_at: :desc)
                       .first

    self.previous_annual_ctc = previous&.annual_ctc
  end

  def combine_allowances_and_bonus
    # If bonus is present and > 0, combine it with allowances
    # This handles both new records and updates to old records that still have separate values
    if bonus.present? && bonus.to_f > 0
      self.allowances = (allowances.to_f || 0) + bonus.to_f
      self.bonus = 0
    end
    # If bonus is 0 or nil, allowances should already contain the total (from frontend)
  end

  def calculate_monthly_ctc
    # Calculate monthly CTC from annual CTC if annual CTC is provided
    # Monthly CTC = Annual CTC ÷ 12
    # Note: Annual CTC should be calculated as Gross Salary + Total Deductions
    # This is handled on the frontend, but we ensure monthly is calculated here too
    if annual_ctc.present? && annual_ctc.to_f > 0
      self.monthly_ctc = (annual_ctc.to_f / 12.0).round(2)
    elsif annual_ctc.to_f.zero? && monthly_ctc.to_f.zero?
      # If both are zero, calculate from gross and deductions
      gross = (basic.to_f || 0) + (hra.to_f || 0) + (allowances.to_f || 0)
      total_deductions = (pf.to_f || 0) + (esi.to_f || 0) + (professional_tax.to_f || 0) + (income_tax.to_f || 0)
      calculated_annual_ctc = gross + total_deductions
      if calculated_annual_ctc > 0
        self.annual_ctc = calculated_annual_ctc.round(2)
        self.monthly_ctc = (calculated_annual_ctc / 12.0).round(2)
      end
    end
  end

  def no_overlapping_periods
    return unless employee_id && effective_from

    # Convert effective_from to date if it's a string
    new_from = effective_from.is_a?(String) ? Date.parse(effective_from) : effective_from
    new_upto = effective_upto.is_a?(String) ? Date.parse(effective_upto) : effective_upto if effective_upto

    # Validate that effective_upto is after effective_from if both are present
    if new_upto && new_from && new_upto < new_from
      errors.add(:effective_upto, "must be after or equal to effective from date")
      return
    end

    # Get all existing structures for this employee (excluding current record if updating)
    existing_structures = employee.salary_structures.where.not(id: id || 0)

    # Check for overlaps with each existing structure
    existing_structures.each do |existing|
      existing_from = existing.effective_from
      existing_upto = existing.effective_upto

      if self.class.periods_overlap?(new_from, new_upto, existing_from, existing_upto)
        existing_period = existing_upto ?
          "#{existing_from} to #{existing_upto}" :
          "#{existing_from} (ongoing)"
        errors.add(:base, "This salary structure period overlaps with an existing structure (Effective from: #{existing_period}). Please choose a different date range.")
        return
      end
    end
  end

  class << self
    # Generate default salary structures for an employee
    # Creates structures with all fields = 0 for months from date_of_joining
    # to the latest existing salary structure month
    # Requirement: "up to the month for which a salary structure exists"
    def generate_defaults_for_employee(employee)
      return [] unless employee&.date_of_joining

      # Get all existing structures for this employee, handling duplicates
      existing_structures = resolve_duplicates(employee.salary_structures.order(:effective_from, :created_at))

      # Determine the end month
      # Requirement: "up to the month for which a salary structure exists"
      # This means we only generate defaults if at least one structure exists
      # and we generate up to that structure's month
      unless existing_structures.any?
        # No structures exist - cannot determine "month for which a salary structure exists"
        return []
      end

      # Find the latest structure by effective_from date
      latest_structure = existing_structures.max_by { |s| s.effective_from }
      end_date = latest_structure.effective_from

      # Ensure we have a valid date
      unless end_date.present?
        # If somehow effective_from is nil, skip this employee
        return []
      end

      end_month = Date.new(end_date.year, end_date.month, 1)

      # Start from the employee's date of joining
      start_month = Date.new(employee.date_of_joining.year, employee.date_of_joining.month, 1)

      # Generate month keys for all months from joining to end month
      months_to_process = []
      current_month = start_month
      while current_month <= end_month
        months_to_process << current_month
        current_month = current_month.next_month
      end

      # Group existing structures by month (year-month)
      existing_by_month = existing_structures.group_by { |s| month_key(s.effective_from) }

      # Create default structures for missing months
      created_structures = []
      months_to_process.each do |month|
        month_key_str = month_key(month)
        # Skip if a structure already exists for this month
        # group_by always returns arrays, so if key exists, array has at least one element
        next if existing_by_month[month_key_str].present?

        # Create default structure with all fields = 0
        default_structure = create!(
          employee: employee,
          department_id: employee.department_id,
          basic: 0,
          hra: 0,
          allowances: 0,
          deductions: 0,
          bonus: 0,
          pf: 0,
          esi: 0,
          professional_tax: 0,
          income_tax: 0,
          annual_ctc: 0,
          monthly_ctc: 0,
          effective_from: month,
          level: nil,
          revision_type: "adjustment",
          notes: "Auto-generated default structure"
        )
        created_structures << default_structure
      end

      created_structures
    end

    # Generate default salary structures for all employees
    def generate_defaults_for_all_employees
      Employee.find_each.map do |employee|
        generate_defaults_for_employee(employee)
      end.flatten
    end

    # Resolve duplicate structures for the same month
    # Uses the latest created structure (by created_at)
    # Filters out structures with nil effective_from dates
    def resolve_duplicates(structures)
      return [] if structures.empty?

      # Filter out structures with nil effective_from (they can't be grouped by month)
      valid_structures = structures.select { |s| s.effective_from.present? }
      return [] if valid_structures.empty?

      # Group by month key
      grouped = valid_structures.group_by { |s| month_key(s.effective_from) }

      # For each month, keep only the latest created structure
      grouped.values.map do |month_structures|
        month_structures.max_by(&:created_at)
      end
    end

    # Get salary structure for a specific month
    # Returns the structure for that month, or a default one if none exists
    def for_month(employee, year, month)
      return nil unless employee&.date_of_joining

      month_date = Date.new(year, month, 1)
      month_key_str = month_key(month_date)

      # Get all structures for this employee
      all_structures = employee.salary_structures.order(:effective_from, :created_at)
      resolved_structures = resolve_duplicates(all_structures)

      # Find structure for this month
      structure = resolved_structures.find { |s| s.effective_from.present? && month_key(s.effective_from) == month_key_str }

      # If not found, return a default structure (in-memory, not saved)
      structure || default_structure_for_month(employee, month_date)
    end

    # Get all salary structures for an employee, with defaults filled in
    # Returns an array of structures (existing or default) for each month
    def complete_structures_for_employee(employee)
      return [] unless employee&.date_of_joining

      # Get existing structures, resolving duplicates
      existing_structures = resolve_duplicates(employee.salary_structures.order(:effective_from, :created_at))

      # Determine the end month
      # If structures exist, use the latest structure month
      # If no structures exist, use current month (for display purposes)
      if existing_structures.any?
        latest_structure = existing_structures.max_by { |s| s.effective_from }
        end_date = latest_structure.effective_from

        if end_date.present?
          end_month = Date.new(end_date.year, end_date.month, 1)
        else
          end_month = Date.current.beginning_of_month
        end
      else
        # For display purposes, show up to current month even if no structures exist
        end_month = Date.current.beginning_of_month
      end

      # Start from the employee's date of joining
      start_month = Date.new(employee.date_of_joining.year, employee.date_of_joining.month, 1)

      # Group existing structures by month
      existing_by_month = existing_structures.group_by { |s| month_key(s.effective_from) }

      # Build complete list
      complete_structures = []
      current_month = start_month
      while current_month <= end_month
        month_key_str = month_key(current_month)
        structure = existing_by_month[month_key_str]&.first

        if structure
          complete_structures << structure
        else
          complete_structures << default_structure_for_month(employee, current_month)
        end

        current_month = current_month.next_month
      end

      complete_structures
    end

    private

    # Generate a month key string (YYYY-MM) from a date
    def month_key(date)
      return nil unless date
      date.strftime("%Y-%m")
    end

    # Create a default structure object (not saved) for a given month
    def default_structure_for_month(employee, month_date)
      new(
        employee: employee,
        department_id: employee.department_id,
        basic: 0,
        hra: 0,
        allowances: 0,
        deductions: 0,
        bonus: 0,
        pf: 0,
        esi: 0,
        professional_tax: 0,
        income_tax: 0,
        annual_ctc: 0,
        monthly_ctc: 0,
        effective_from: month_date,
        level: nil,
        revision_type: "adjustment"
      )
    end
  end
end
