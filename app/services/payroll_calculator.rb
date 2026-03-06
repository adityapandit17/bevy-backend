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

    # Total days in the month (including weekends - all days are payable by default)
    total_days = PayrollMonth.range(@month).count
    total_days = 1 if total_days.zero? # guard against division by zero

    payable_days, unpaid_days = calculate_payable_days(total_days)
    per_day_rate = (earnings[:basic] / total_days).to_d
    leave_deduction = (per_day_rate * unpaid_days).round(2)

    deductions = build_deductions(monthly, leave_deduction)
    net_salary = (earnings[:gross] - leave_deduction).round(2)

    Result.new(
      gross: earnings[:gross],
      net: net_salary,
      working_days: total_days, # Total days including weekends
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
      allowances: monthly.allowances, # Allowances already includes annual bonus + other allowances
      bonus: 0, # Bonus is now included in allowances
      gross: monthly.gross
    }.transform_values { |v| BigDecimal(v || 0) }
  end

  def build_deductions(monthly, leave_deduction)
    # Use deduction values from salary structure (already converted to monthly)
    # This ensures consistency with PayrollBreakdown and frontend calculations
    pf = BigDecimal(monthly.pf || 0)
    esi = BigDecimal(monthly.esi || 0)
    professional_tax = BigDecimal(monthly.professional_tax || 0)
    income_tax = BigDecimal(monthly.income_tax || 0)

    {
      pf: pf,
      esi: esi,
      professional_tax: professional_tax,
      income_tax: income_tax,
      leave_deduction: BigDecimal(leave_deduction || 0)
    }
  end

  def calculate_payable_days(total_days)
    range = PayrollMonth.range(@month)
    # Get all dates in the month (including weekends)
    all_dates = range.to_a

    # Get attendance records for all days in the month
    attendance = attendance_by_date(all_dates)
    leaves = leaves_by_date(range)

    # Start with full month salary (all days are payable by default)
    # Weekends (Saturdays and Sundays) are considered always present by default
    payable = BigDecimal(total_days)
    deductions = 0.to_d

    # Process each day in the month (including weekends)
    all_dates.each do |day|
      # If there's an attendance record for this day, check for deductions
      if attendance[day]
        deduction = deduction_from_attendance(attendance[day])
        deductions += deduction
      # If there's an approved leave for this day, check for deductions
      elsif leaves[day]
        deduction = deduction_from_leave(leaves[day])
        deductions += deduction
      else
        # No attendance record and no leave
        if weekend?(day)
          # Weekends remain payable by default
        else
          # Weekday with no record counts as absent
          deductions += 1.to_d
        end
      end
    end

    # Calculate payable days after deductions
    payable = payable - deductions
    payable = [ payable, 0.to_d ].max # Ensure payable is not negative
    unpaid = BigDecimal(total_days) - payable
    [ payable, unpaid ]
  end

  def attendance_by_date(dates)
    AttendanceRecord
      .where(employee_id: @employee.id, date: dates)
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
        # Check all days in the leave period (including weekends)
        # Weekends will be handled by deduction logic (no deduction for weekends)
        leave_days.each do |day|
          # Only include days within the payroll month range
          h[day] = leave if range.include?(day)
        end
      end
  end

  # Calculate deduction from attendance record
  # Full month salary is granted by default, so we only deduct for:
  # - half_day: deduct 0.5 days
  # - absent: deduct 1.0 days
  # All other statuses (present, late, work_from_home, early_departure) = no deduction
  def deduction_from_attendance(record)
    case record.status
    when "half_day"
      BigDecimal("0.5") # Deduct half day
    when "absent"
      1.to_d # Deduct full day
    when "present", "late", "work_from_home", "early_departure"
      0.to_d # No deduction (full day payable)
    else
      # Unknown status, treat as absent (deduct full day)
      1.to_d
    end
  end

  # Calculate deduction from leave record
  # Full month salary is granted by default, so we only deduct for unpaid leaves
  def deduction_from_leave(leave)
    paid_leave = leave.leave_type != "unpaid"
    return 0.to_d if paid_leave # Paid leave = no deduction

    # Unpaid leave: deduct based on whether it's half day or full day
    leave.half_day? ? BigDecimal("0.5") : 1.to_d
  end

    def weekend?(date)
      date.saturday? || date.sunday?
    end
end
