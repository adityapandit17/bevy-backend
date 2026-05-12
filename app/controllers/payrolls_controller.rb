class PayrollsController < ApplicationController
  before_action :set_payroll, only: [ :show, :update, :destroy ]
  # before_action :authorize_payroll_access!

  def index
    # authorize!("payrolls", "index")
    @payrolls = Payroll.for_current_company.includes(:employee)
    render json: @payrolls.as_json(
      include: {
        employee: {
          only: [ :id, :first_name, :last_name, :employee_code, :department_id ]
        }
      }
    )
  end

  def show
    # authorize!("payrolls", "show")
    render json: @payroll
  end

  def calculation_breakdown
    payroll = find_in_tenant(Payroll, params[:id])
    employee = payroll.employee

    # Parse the month from payroll
    month_date = PayrollMonth.parse(payroll.month)
    range = PayrollMonth.range(month_date)
    all_dates = range.to_a

    # Get attendance records for the month
    attendance_records = AttendanceRecord
      .where(employee_id: employee.id, date: all_dates)
      .order(:date)
      .map do |rec|
        {
          date: rec.date,
          status: rec.status,
          status_label: rec.status_label,
          deduction: calculate_deduction_from_status(rec.status)
        }
      end

    # Get leaves for the month
    leaves = LeaveRequest
      .where(employee_id: employee.id, status: "approved")
      .where("start_date <= ? AND end_date >= ?", range.end, range.begin)
      .map do |leave|
        leave_days = (leave.start_date..leave.end_date).to_a.select { |d| range.include?(d) }
        {
          id: leave.id,
          leave_type: leave.leave_type,
          start_date: leave.start_date,
          end_date: leave.end_date,
          days: leave_days,
          half_day: leave.half_day?,
          deduction: leave.leave_type == "unpaid" ? (leave.half_day? ? 0.5 : 1.0) : 0.0
        }
      end

    # Calculate day-by-day breakdown
    day_breakdown = all_dates.map do |date|
      attendance = attendance_records.find { |r| r[:date] == date }
      leave = leaves.find { |l| l[:days].include?(date) }

      deduction = 0.0
      reason = nil

      if attendance
        deduction = attendance[:deduction]
        reason = attendance[:status_label]
      elsif leave
        deduction = leave[:deduction]
        reason = leave[:leave_type] == "unpaid" ? "Unpaid Leave" : "Paid Leave"
      else
        # No attendance and no leave
        if date.saturday? || date.sunday?
          # Weekends are payable by default
          reason = "Weekend (Always Present)"
          deduction = 0.0
        else
          # Weekday with no record counts as absent
          reason = "Absent (No Record)"
          deduction = 1.0
        end
      end

      {
        date: date,
        day_name: date.strftime("%A"),
        is_weekend: date.saturday? || date.sunday?,
        attendance_status: attendance ? attendance[:status] : nil,
        attendance_label: attendance ? attendance[:status_label] : nil,
        leave_type: leave ? leave[:leave_type] : nil,
        deduction: deduction,
        reason: reason
      }
    end

    # Calculate summary
    total_days = all_dates.count
    total_deductions = day_breakdown.sum { |d| d[:deduction] }
    payable_days = total_days - total_deductions
    # Get salary structure
    structure = PayrollBreakdown.for_employee(employee, month: month_date)
    monthly = structure&.monthly
    gross_salary = monthly ? monthly.gross : (payroll.gross_salary || 0)
    per_day_rate = total_days > 0 ? (monthly.basic / total_days) : 0

    # Get earnings and deductions breakdowns
    earnings_breakdown = payroll.earnings_breakdown || {}
    deductions_breakdown = payroll.deductions_breakdown || {}

    # Calculate CTC dynamically: Monthly CTC = Gross Earnings + Total Deductions
    # Annual CTC = Monthly CTC × 12
    gross_earnings = begin
      if earnings_breakdown.is_a?(Hash)
        # Try to get gross directly, or sum all earnings components
        if earnings_breakdown["gross"].present?
          earnings_breakdown["gross"].to_f
        else
          # Sum all earnings components as fallback
          (earnings_breakdown["basic"].to_f || 0) +
          (earnings_breakdown["hra"].to_f || 0) +
          (earnings_breakdown["allowances"].to_f || 0) +
          (earnings_breakdown["bonus"].to_f || 0)
        end
      else
        gross_salary
      end
    end

    total_deductions_amount = begin
      if deductions_breakdown.is_a?(Hash)
        # Sum all deduction components EXCEPT leave_deduction
        # CTC should only include statutory deductions, not leave deductions
        (deductions_breakdown["pf"].to_f || 0) +
        (deductions_breakdown["esi"].to_f || 0) +
        (deductions_breakdown["professional_tax"].to_f || 0) +
        (deductions_breakdown["income_tax"].to_f || 0)
        # Note: leave_deduction is explicitly excluded from CTC calculation
      else
        # Fallback: calculate from structure (statutory deductions only)
        if monthly
          (monthly.pf.to_f || 0) + (monthly.esi.to_f || 0) +
          (monthly.professional_tax.to_f || 0) + (monthly.income_tax.to_f || 0)
        else
          0
        end
      end
    end

    # Calculate CTC: Monthly CTC = Gross Earnings + Statutory Deductions (excluding leave deduction)
    calculated_monthly_ctc = gross_earnings + total_deductions_amount
    calculated_annual_ctc = calculated_monthly_ctc * 12

    breakdown = {
      payroll: {
        id: payroll.id,
        month: payroll.month,
        gross_salary: payroll.gross_salary,
        net_salary: payroll.net_salary,
        status: payroll.status,
        processed_at: payroll.processed_at
      },
      employee: {
        id: employee.id,
        name: employee.name
      },
      calculation: {
        total_days: total_days,
        payable_days: payable_days,
        unpaid_days: total_deductions,
        per_day_rate: per_day_rate,
        total_deduction_amount: begin
          # Calculate total deductions from deductions_breakdown (includes all statutory + leave deductions)
          if payroll.deductions_breakdown.is_a?(Hash)
            payroll.deductions_breakdown["leave_deduction"].to_f
          else
            payroll.leave_deduction || 0
          end
        end,
        annual_ctc: calculated_annual_ctc,
        monthly_ctc: calculated_monthly_ctc
      },
      earnings_breakdown: earnings_breakdown,
      deductions_breakdown: deductions_breakdown,
      attendance_summary: begin
        present_statuses = [ "present", "late", "work_from_home", "early_departure" ]
        present_count = day_breakdown.count do |d|
          present_statuses.include?(d[:attendance_status]) ||
            (d[:leave_type] && d[:deduction].to_f.zero?) ||
            (d[:attendance_status].nil? && d[:leave_type].nil? && d[:is_weekend])
        end
        half_day_count = day_breakdown.count { |d| d[:attendance_status] == "half_day" || (d[:leave_type] == "unpaid" && d[:deduction].to_f == 0.5) }
        absent_count = day_breakdown.count do |d|
          d[:attendance_status] == "absent" ||
            (d[:leave_type] == "unpaid" && d[:deduction].to_f == 1.0) ||
            (!d[:attendance_status] && !d[:leave_type] && !d[:is_weekend])
        end
        no_record_count = day_breakdown.count { |d| d[:attendance_status].nil? && d[:leave_type].nil? }
        {
          present: present_count,
          half_day: half_day_count,
          absent: absent_count,
          no_record: no_record_count
        }
      end,
      day_breakdown: day_breakdown,
      attendance_records: attendance_records,
      leaves: leaves
    }

    render json: breakdown
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Payroll not found" }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create
    authorize!("payrolls", "create")
    @payroll = Payroll.new(payroll_params)
    if @payroll.save
      render json: @payroll, status: :created
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize!("payrolls", "update")
    return if performed? # Stop if authorization already rendered a response

    # Store original values for comparison
    original_gross = @payroll.gross_salary.to_f
    original_earnings_breakdown = @payroll.earnings_breakdown || {}

    # Get the new gross_salary from params (before update)
    new_gross_param = params[:payroll][:gross_salary] if params[:payroll] && params[:payroll][:gross_salary]

    # Update basic fields first (gross_salary, net_salary, leave_deduction, unpaid_days, status)
    if @payroll.update(payroll_params)
      # Get the updated gross_salary value
      new_gross = new_gross_param ? new_gross_param.to_f : @payroll.gross_salary.to_f

      # Handle gross_salary changes: adjust allowances in earnings_breakdown
      # Only adjust if gross_salary actually changed
      if new_gross > 0 && new_gross != original_gross
        # Calculate the difference in gross salary
        gross_difference = new_gross - original_gross

        # Get current earnings breakdown (use updated value or fallback to original)
        earnings_breakdown = @payroll.earnings_breakdown || original_earnings_breakdown

        # Ensure earnings_breakdown is a hash with string keys
        if earnings_breakdown.is_a?(Hash)
          earnings_breakdown = earnings_breakdown.deep_dup
          # Normalize keys to strings
          earnings_breakdown = earnings_breakdown.transform_keys(&:to_s)
        else
          earnings_breakdown = {}
        end

        # Extract current values from earnings_breakdown
        # If not present, try to get from salary structure as fallback
        basic = earnings_breakdown["basic"].to_f
        hra = earnings_breakdown["hra"].to_f
        current_allowances = earnings_breakdown["allowances"].to_f
        bonus = earnings_breakdown["bonus"].to_f || 0

        # If earnings_breakdown is empty, try to reconstruct from salary structure
        if basic.zero? && hra.zero? && current_allowances.zero?
          employee = @payroll.employee
          month_date = PayrollMonth.parse(@payroll.month)
          structure = PayrollBreakdown.for_employee(employee, month: month_date)
          if structure&.monthly
            monthly = structure.monthly
            basic = monthly.basic.to_f
            hra = monthly.hra.to_f
            current_allowances = monthly.allowances.to_f
            bonus = 0 # Bonus is included in allowances
          end
        end

        # Lock basic salary and HRA - they should not change
        # Adjust allowances by the gross difference
        new_allowances = current_allowances + gross_difference

        # Ensure allowances don't go negative
        # Minimum allowances = new_gross - basic - hra - bonus
        min_allowances = new_gross - basic - hra - bonus
        new_allowances = [ new_allowances, min_allowances ].max

        # Update earnings_breakdown with adjusted values
        earnings_breakdown["basic"] = basic.round(2)
        earnings_breakdown["hra"] = hra.round(2)
        earnings_breakdown["allowances"] = new_allowances.round(2)
        earnings_breakdown["bonus"] = bonus.round(2)
        earnings_breakdown["gross"] = new_gross.round(2)

        # Update the payroll record with adjusted earnings_breakdown
        @payroll.update_column(:earnings_breakdown, earnings_breakdown)
      end

      # Recalculate net_salary if leave_deduction changed or gross_salary changed
      # Net = Gross - Leave Deduction (statutory deductions are already included in gross)
      if @payroll.leave_deduction.present?
        new_net = @payroll.gross_salary.to_f - @payroll.leave_deduction.to_f
        @payroll.update_column(:net_salary, new_net.round(2))
      end

      # Update deductions_breakdown to include the updated leave_deduction
      # This ensures the updated value is reflected in payroll records, payslip, and calculation breakdown
      if params[:payroll] && params[:payroll].has_key?(:leave_deduction)
        deductions_breakdown = @payroll.deductions_breakdown || {}
        # Ensure deductions_breakdown is a hash with string keys
        if deductions_breakdown.is_a?(Hash)
          deductions_breakdown = deductions_breakdown.deep_dup
          deductions_breakdown = deductions_breakdown.transform_keys(&:to_s)
        else
          deductions_breakdown = {}
        end

        # Get statutory deductions from existing breakdown or structure
        if deductions_breakdown.empty? || !deductions_breakdown.key?("pf")
          employee = @payroll.employee
          month_date = PayrollMonth.parse(@payroll.month)
          structure = PayrollBreakdown.for_employee(employee, month: month_date)
          if structure&.monthly
            monthly = structure.monthly
            deductions_breakdown["pf"] = monthly.pf.to_f.round(2)
            deductions_breakdown["esi"] = monthly.esi.to_f.round(2)
            deductions_breakdown["professional_tax"] = monthly.professional_tax.to_f.round(2)
            deductions_breakdown["income_tax"] = monthly.income_tax.to_f.round(2)
          end
        end

        # Update leave_deduction in deductions_breakdown
        deductions_breakdown["leave_deduction"] = @payroll.leave_deduction.to_f.round(2)

        # Update the payroll record with updated deductions_breakdown
        @payroll.update_column(:deductions_breakdown, deductions_breakdown)
      end

      # Reload to get updated values
      @payroll.reload
      render json: @payroll, status: :ok
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize!("payrolls", "destroy")
    @payroll.destroy
    head :no_content
  end

  def process_month
    # Temporary: allow any authenticated user to process payroll (adjust with proper permissions later)
    # authorize!("payrolls", "create")
    month = params[:month] || Date.current
    preview = ActiveModel::Type::Boolean.new.cast(params[:preview])

    result = PayrollProcessor.new(month: month, preview: preview, company_id: Current.company.id).call

    render json: {
      month: PayrollMonth.label(month),
      processed: result.processed,
      created: result.created,
      updated: result.updated,
      skipped: result.skipped,
      errors: result.errors,
      payrolls: result.payrolls
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity unless performed?
  end

  private

  def set_payroll
    @payroll = find_in_tenant(Payroll, params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def authorize_payroll_access!
    case action_name
    when "index", "show"
      authorize!("payrolls", "index")
    when "create"
      authorize!("payrolls", "create")
    when "update"
      authorize!("payrolls", "update")
    when "destroy"
      authorize!("payrolls", "destroy")
    end
  end

  def payroll_params
    params.require(:payroll).permit(:employee_id, :month, :gross_salary, :net_salary, :status, :leave_deduction, :unpaid_days)
  end

  def calculate_deduction_from_status(status)
    case status
    when "half_day"
      0.5
    when "absent"
      1.0
    else
      0.0
    end
  end
end
