class SalaryStructure < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :effective_from, presence: true, if: -> { persisted? || effective_from.present? }

  # Generate default salary structures for an employee
  # Creates structures with all fields = 0 for months from date_of_joining
  # to the latest existing salary structure month
  # Requirement: "up to the month for which a salary structure exists"
  def self.generate_defaults_for_employee(employee)
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
        effective_from: month,
        level: nil
      )
      created_structures << default_structure
    end

    created_structures
  end

  # Generate default salary structures for all employees
  def self.generate_defaults_for_all_employees
    Employee.find_each.map do |employee|
      generate_defaults_for_employee(employee)
    end.flatten
  end

  # Resolve duplicate structures for the same month
  # Uses the latest created structure (by created_at)
  # Filters out structures with nil effective_from dates
  def self.resolve_duplicates(structures)
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
  def self.for_month(employee, year, month)
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
  def self.complete_structures_for_employee(employee)
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
  def self.month_key(date)
    return nil unless date
    date.strftime("%Y-%m")
  end

  # Create a default structure object (not saved) for a given month
  def self.default_structure_for_month(employee, month_date)
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
      effective_from: month_date,
      level: nil
    )
  end
end
