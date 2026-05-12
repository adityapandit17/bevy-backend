class PayrollProcessor
  Result = Struct.new(
    :month,
    :processed,
    :created,
    :updated,
    :skipped,
    :errors,
    :payrolls,
    keyword_init: true
  )

  def initialize(month:, preview: false, company_id: nil)
    @month = PayrollMonth.parse(month)
    @preview = preview
    @company_id = company_id || Current.company&.id
    @errors = []
    @created = 0
    @updated = 0
    @skipped = 0
    @persisted_payrolls = []
  end

  def call
    raise ArgumentError, "company_id is required for payroll processing" if @company_id.blank?

    ActiveRecord::Base.transaction do
      Employee.where(company_id: @company_id).active.includes(:department, :salary_structures).find_each do |employee|
        process_employee(employee)
      end

      raise ActiveRecord::Rollback if @preview
    end

    Result.new(
      month: @month,
      processed: @created + @updated,
      created: @created,
      updated: @updated,
      skipped: @skipped,
      errors: @errors,
      payrolls: @persisted_payrolls
    )
  end

  private

  def process_employee(employee)
    calculator = PayrollCalculator.new(employee, month: @month, weekend_only: true)
    result = calculator.call

    payroll = find_or_initialize_payroll(employee)

    # Check if payroll was manually edited after processing
    # If updated_at > processed_at, it means the payroll was manually edited
    # We need to reload to get the actual database values (not just what's in memory)
    payroll.reload if !payroll.new_record?

    manually_edited = !payroll.new_record? &&
                      payroll.processed_at.present? &&
                      payroll.updated_at.present? &&
                      payroll.updated_at > payroll.processed_at

    if manually_edited
      # Preserve manually edited values (gross_salary, net_salary, leave_deduction)
      # Only update fields that are typically not manually edited
      payroll.month = PayrollMonth.label(@month)
      payroll.status = "processed"
      payroll.working_days = result.working_days
      payroll.payable_days = result.payable_days
      payroll.unpaid_days = result.unpaid_days
      # Preserve existing earnings_breakdown and deductions_breakdown if they exist
      # Only update if they're missing
      if payroll.earnings_breakdown.blank? || payroll.earnings_breakdown.empty?
        payroll.earnings_breakdown = result.earnings_breakdown
      end
      if payroll.deductions_breakdown.blank? || payroll.deductions_breakdown.empty?
        payroll.deductions_breakdown = result.deductions_breakdown
      else
        # Update deductions_breakdown to ensure leave_deduction matches the saved value
        # but preserve other statutory deductions
        deductions_breakdown = payroll.deductions_breakdown.dup
        deductions_breakdown = deductions_breakdown.transform_keys(&:to_s) if deductions_breakdown.is_a?(Hash)
        deductions_breakdown["leave_deduction"] = payroll.leave_deduction.to_f.round(2) if payroll.leave_deduction.present?
        payroll.deductions_breakdown = deductions_breakdown
      end
      # Don't update processed_at for manually edited records to preserve the edit timestamp
    else
      # New record or not manually edited - use calculated values
      payroll.gross_salary = result.gross
      payroll.net_salary = result.net
      payroll.month = PayrollMonth.label(@month)
      payroll.status = "processed"
      payroll.working_days = result.working_days
      payroll.payable_days = result.payable_days
      payroll.unpaid_days = result.unpaid_days
      payroll.leave_deduction = result.leave_deduction
      payroll.earnings_breakdown = result.earnings_breakdown
      payroll.deductions_breakdown = result.deductions_breakdown
      payroll.processed_at = Time.current
    end

    if payroll.new_record?
      @created += 1
    elsif payroll.changed?
      @updated += 1
    else
      @skipped += 1
    end

    payroll.save!
    @persisted_payrolls << payroll
  rescue StandardError => e
    @errors << "Failed processing #{employee.name}: #{e.message}"
  end

  def find_or_initialize_payroll(employee)
    Payroll.find_or_initialize_by(employee_id: employee.id, month: PayrollMonth.label(@month))
  end
end
