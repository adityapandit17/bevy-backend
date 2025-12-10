class PayrollCalculator
  Result = Struct.new(
    :gross,
    :net,
    :working_days,
    :payable_days,
    :unpaid_days,
    :leave_deduction,
    :earnings_breakdown,
    :deductions_breakdown,
    keyword_init: true
  )

  def initialize(employee, month:, weekend_only: true)
    @employee = employee
    @month = PayrollMonth.parse(month)
    @weekend_only = weekend_only
  end

  def call
    structure = PayrollBreakdown.for_employee(@employee, month: @month)
    raise "No salary structure for #{@employee.name} (##{@employee.id})" unless structure.present?

    monthly = structure.monthly
    earnings = build_earnings(monthly)

    working_days = PayrollMonth.working_days(@month, weekend_only: @weekend_only)
    working_days = 1 if working_days.zero? # guard against division by zero

    payable_days, unpaid_days = calculate_payable_days(working_days)
    per_day_rate = (earnings[:gross] / working_days).to_d
    leave_deduction = (per_day_rate * unpaid_days).round(2)

    deductions = build_deductions(monthly, leave_deduction)
    net_salary = (earnings[:gross] - deductions.values.sum).round(2)

    Result.new(
      gross: earnings[:gross],
      net: net_salary,
      working_days: working_days,
      payable_days: payable_days,
      unpaid_days: unpaid_days,
      leave_deduction: leave_deduction,
      earnings_breakdown: earnings,
      deductions_breakdown: deductions
    )
  end

  private

  def build_earnings(monthly)
    {
      basic: monthly.basic,
      hra: monthly.hra,
      allowances: monthly.allowances,
      bonus: monthly.respond_to?(:bonus) ? monthly.bonus : 0,
      gross: monthly.gross
    }.transform_values { |v| BigDecimal(v || 0) }
  end

  def build_deductions(monthly, leave_deduction)
    basic = BigDecimal(monthly.basic || 0)
    gross = BigDecimal(monthly.gross || 0)

    pf = (basic * BigDecimal("0.12")).round(2)
    esi = gross <= 21_000 ? (gross * BigDecimal("0.0075")).round(2) : BigDecimal("0")
    professional_tax = BigDecimal("200")
    income_tax = BigDecimal(monthly.respond_to?(:income_tax) ? monthly.income_tax || 0 : 0)

    {
      pf: pf,
      esi: esi,
      professional_tax: professional_tax,
      income_tax: income_tax,
      leave_deduction: BigDecimal(leave_deduction || 0)
    }
  end

  def calculate_payable_days(working_days)
    range = PayrollMonth.range(@month)
    working_dates = range.to_a.select { |d| PayrollMonth.weekday?(d) }

    attendance = attendance_by_date(working_dates)
    leaves = leaves_by_date(range)

    payable = 0.to_d

    working_dates.each do |day|
      if attendance[day]
        payable += payable_from_attendance(attendance[day])
      elsif leaves[day]
        payable += payable_from_leave(leaves[day])
      else
        # Absent, counts as 0
      end
    end

    payable = [payable, working_days].min
    unpaid = BigDecimal(working_days) - payable
    [payable, unpaid]
  end

  def attendance_by_date(working_dates)
    AttendanceRecord
      .where(employee_id: @employee.id, date: working_dates)
      .each_with_object({}) do |rec, h|
        h[rec.date] = rec
      end
  end

  def leaves_by_date(range)
    LeaveRequest
      .where(employee_id: @employee.id, status: "approved")
      .where("start_date <= ? AND end_date >= ?", range.end, range.begin)
      .each_with_object({}) do |leave, h|
        leave_days = (leave.start_date..leave.end_date).to_a
        leave_days.each do |day|
          next unless PayrollMonth.weekday?(day)
          h[day] = leave
        end
      end
  end

  def payable_from_attendance(record)
    case record.status
    when "present", "late", "work_from_home"
      1.to_d
    when "half_day"
      BigDecimal("0.5")
    else
      0.to_d
    end
  end

  def payable_from_leave(leave)
    paid_leave = leave.leave_type != "unpaid"
    return 0.to_d unless paid_leave

    leave.half_day? ? BigDecimal("0.5") : 1.to_d
  end
end

