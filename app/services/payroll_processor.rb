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

  def initialize(month:, preview: false)
    @month = PayrollMonth.parse(month)
    @preview = preview
    @errors = []
    @created = 0
    @updated = 0
    @skipped = 0
    @persisted_payrolls = []
  end

  def call
    ActiveRecord::Base.transaction do
      Employee.active.includes(:department, :salary_structures).find_each do |employee|
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

