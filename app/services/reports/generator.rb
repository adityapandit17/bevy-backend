module Reports
  class Generator
    REPORT_TYPES = %w[
      employee-directory department-wise new-joiners employee-turnover
      daily-attendance late-arrivals overtime
      monthly-payroll salary-structure tax-deductions bonus-incentives
      leave-balance leave-trends pending-approvals leave-utilization
      performance-reviews goal-tracking training-reports appraisal-summary
      hiring-pipeline source-analysis time-to-hire interview-feedback
    ].freeze

    def initialize(type:, params: {})
      @type = type.to_s
      @params = params
      @start_date, @end_date = Period.resolve(params)
    end

    def generate
      raise ArgumentError, "Unknown report type" unless REPORT_TYPES.include?(@type)

      send(:"report_#{@type.tr('-', '_')}")
    end

    private

    def base_payload(title:, description:, summary: [], columns: [], rows: [])
      {
        type: @type,
        title: title,
        description: description,
        generated_at: Time.current.iso8601,
        period: {
          start_date: @start_date.iso8601,
          end_date: @end_date.iso8601,
          label: Period.label(@start_date, @end_date)
        },
        summary: summary,
        columns: columns,
        rows: rows
      }
    end

    def col(key, label, align: "left")
      { key: key, label: label, align: align }
    end

    def active_employees
      @active_employees ||= Employee.active.includes(:department, :manager).order(:first_name, :last_name)
    end

    def daily_target_hours
      company = ActsAsTenant.current_tenant
      weekly = (company&.weekly_working_hours || 40).to_f
      (weekly / AttendanceComplianceService::WORKDAYS_PER_WEEK).round(2)
    end

    # --- Employee reports ---

    def report_employee_directory
      rows = active_employees.map do |e|
        {
          employee_id: e.display_id,
          employee_number: e.employee_number,
          name: e.name,
          email: e.email,
          department: e.department&.name,
          designation: e.designation,
          manager: e.manager&.name,
          status: e.status_label,
          date_of_joining: e.date_of_joining&.iso8601
        }
      end

      base_payload(
        title: "Employee Directory",
        description: "Complete list of active employees",
        summary: [
          { label: "Total employees", value: rows.size }
        ],
        columns: [
          col("employee_id", "Employee ID"),
          col("name", "Name"),
          col("email", "Email"),
          col("department", "Department"),
          col("designation", "Designation"),
          col("manager", "Manager"),
          col("status", "Status"),
          col("date_of_joining", "Joining date")
        ],
        rows: rows
      )
    end

    def report_department_wise
      grouped = active_employees.group_by { |e| e.department&.name || "Unassigned" }
      rows = grouped.map do |dept, members|
        {
          department: dept,
          employee_count: members.size,
          designations: members.map(&:designation).compact.uniq.join(", ")
        }
      end.sort_by { |r| -r[:employee_count] }

      base_payload(
        title: "Department Wise Report",
        description: "Employee distribution by department",
        summary: [
          { label: "Departments", value: rows.size },
          { label: "Total employees", value: rows.sum { |r| r[:employee_count] } }
        ],
        columns: [
          col("department", "Department"),
          col("employee_count", "Employees", align: "right"),
          col("designations", "Designations")
        ],
        rows: rows
      )
    end

    def report_new_joiners
      joiners = Employee.where(status: %w[active onboarding probation])
                      .where(date_of_joining: @start_date..@end_date)
                      .includes(:department)
                      .order(date_of_joining: :desc)

      rows = joiners.map do |e|
        {
          name: e.name,
          email: e.email,
          department: e.department&.name,
          designation: e.designation,
          date_of_joining: e.date_of_joining&.iso8601,
          status: e.status_label
        }
      end

      base_payload(
        title: "New Joiners Report",
        description: "Recent hires in the selected period",
        summary: [ { label: "New joiners", value: rows.size } ],
        columns: [
          col("name", "Name"),
          col("email", "Email"),
          col("department", "Department"),
          col("designation", "Designation"),
          col("date_of_joining", "Joining date"),
          col("status", "Status")
        ],
        rows: rows
      )
    end

    def report_employee_turnover
      terminated = Employee.where(status: %w[inactive terminated])
                           .where(updated_at: @start_date.beginning_of_day..@end_date.end_of_day)
      active_count = Employee.active.count
      term_count = terminated.count
      rate = active_count.positive? ? ((term_count.to_f / active_count) * 100).round(1) : 0

      rows = terminated.includes(:department).order(updated_at: :desc).map do |e|
        {
          name: e.name,
          department: e.department&.name,
          designation: e.designation,
          status: e.status_label,
          date_of_joining: e.date_of_joining&.iso8601,
          last_updated: e.updated_at&.to_date&.iso8601
        }
      end

      base_payload(
        title: "Employee Turnover",
        description: "Attrition and departures in the selected period",
        summary: [
          { label: "Departures", value: term_count },
          { label: "Active workforce", value: active_count },
          { label: "Turnover rate", value: "#{rate}%" }
        ],
        columns: [
          col("name", "Name"),
          col("department", "Department"),
          col("designation", "Designation"),
          col("status", "Status"),
          col("date_of_joining", "Joined"),
          col("last_updated", "Last updated")
        ],
        rows: rows
      )
    end

    # --- Attendance reports ---

    def report_daily_attendance
      date = @params[:date].present? ? Date.parse(@params[:date]) : Date.current
      records = AttendanceRecord.includes(:employee, :attendance_sessions)
                                .where(date: date)
                                .joins(:employee)
                                .where(employees: { status: "active" })
                                .order("employees.first_name")

      rows = records.map do |r|
        first_in = r.attendance_sessions.minimum(:check_in)
        {
          employee: r.employee.name,
          department: r.employee.department&.name,
          status: r.status_label,
          check_in: first_in&.strftime("%H:%M") || "—",
          hours: r.working_hours.to_f.round(2)
        }
      end

      present = records.count { |r| r.status != "absent" }
      absent = records.count { |r| r.status == "absent" }
      late = records.count { |r| r.status == "late" }

      base_payload(
        title: "Daily Attendance",
        description: "Attendance summary for #{date.strftime('%B %d, %Y')}",
        summary: [
          { label: "Present / marked", value: present },
          { label: "Absent", value: absent },
          { label: "Late", value: late }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("status", "Status"),
          col("check_in", "Check-in"),
          col("hours", "Hours", align: "right")
        ],
        rows: rows
      )
    end

    def report_late_arrivals
      records = AttendanceRecord.includes(:employee)
                                .where(date: @start_date..@end_date, status: "late")
                                .joins(:employee)
                                .where(employees: { status: "active" })

      by_employee = records.group_by(&:employee_id)
      rows = by_employee.map do |_id, recs|
        emp = recs.first.employee
        {
          employee: emp.name,
          department: emp.department&.name,
          late_count: recs.size,
          dates: recs.map { |r| r.date.strftime("%Y-%m-%d") }.join(", ")
        }
      end.sort_by { |r| -r[:late_count] }

      base_payload(
        title: "Late Arrivals Report",
        description: "Employees with late attendance in the selected period",
        summary: [
          { label: "Employees with late marks", value: rows.size },
          { label: "Total late instances", value: records.size }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("late_count", "Late count", align: "right"),
          col("dates", "Dates")
        ],
        rows: rows
      )
    end

    def report_overtime
      target = daily_target_hours
      records = AttendanceRecord.includes(:employee)
                                .where(date: @start_date..@end_date)
                                .where("working_hours > ?", target)
                                .joins(:employee)
                                .where(employees: { status: "active" })
                                .order(date: :desc)

      rows = records.map do |r|
        hours = r.working_hours.to_f
        {
          employee: r.employee.name,
          department: r.employee.department&.name,
          date: r.date.iso8601,
          hours_worked: hours.round(2),
          overtime_hours: (hours - target).round(2)
        }
      end

      total_ot = rows.sum { |r| r[:overtime_hours] }

      base_payload(
        title: "Overtime Report",
        description: "Hours worked beyond #{target}h daily target",
        summary: [
          { label: "Overtime instances", value: rows.size },
          { label: "Total overtime hours", value: total_ot.round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("date", "Date"),
          col("hours_worked", "Hours worked", align: "right"),
          col("overtime_hours", "Overtime", align: "right")
        ],
        rows: rows
      )
    end

    # --- Payroll reports ---

    def report_monthly_payroll
      month_label = @params[:month].presence || Date.current.strftime("%B %Y")
      payrolls = Payroll.includes(:employee)
                        .where(month: month_label, status: "processed")
                        .joins(:employee)
                        .order("employees.first_name")

      rows = payrolls.map do |p|
        emp = p.employee
        {
          employee: emp.name,
          department: emp.department&.name,
          month: p.month,
          gross_salary: p.gross_salary.to_f.round(2),
          leave_deduction: p.leave_deduction.to_f.round(2),
          net_salary: p.net_salary.to_f.round(2),
          payable_days: p.payable_days.to_f
        }
      end

      base_payload(
        title: "Monthly Payroll",
        description: "Processed payroll for #{month_label}",
        summary: [
          { label: "Employees paid", value: rows.size },
          { label: "Total net payout", value: rows.sum { |r| r[:net_salary] }.round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("gross_salary", "Gross", align: "right"),
          col("leave_deduction", "Leave ded.", align: "right"),
          col("net_salary", "Net pay", align: "right"),
          col("payable_days", "Payable days", align: "right")
        ],
        rows: rows
      )
    end

    def report_salary_structure
      structures = SalaryStructure.includes(employee: :department)
                                  .joins(:employee)
                                  .where("effective_from <= ? AND (effective_upto IS NULL OR effective_upto >= ?)",
                                         @end_date, @start_date)
                                  .order("employees.first_name")

      latest_by_employee = structures.group_by(&:employee_id).transform_values do |list|
        list.max_by(&:effective_from)
      end

      rows = latest_by_employee.values.map do |s|
        emp = s.employee
        {
          employee: emp&.name,
          department: emp&.department&.name,
          basic: s.basic.to_f.round(2),
          hra: s.hra.to_f.round(2),
          allowances: s.allowances.to_f.round(2),
          monthly_ctc: s.monthly_ctc.to_f.round(2),
          effective_from: s.effective_from&.iso8601
        }
      end

      base_payload(
        title: "Salary Structure",
        description: "Current salary structures by employee",
        summary: [
          { label: "Employees with structures", value: rows.size },
          { label: "Avg monthly CTC", value: rows.empty? ? 0 : (rows.sum { |r| r[:monthly_ctc] } / rows.size).round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("basic", "Basic", align: "right"),
          col("hra", "HRA", align: "right"),
          col("allowances", "Allowances", align: "right"),
          col("monthly_ctc", "Monthly CTC", align: "right"),
          col("effective_from", "Effective from")
        ],
        rows: rows
      )
    end

    def report_tax_deductions
      month_label = @params[:month].presence
      scope = Payroll.includes(:employee).where(status: "processed")
      scope = scope.where(month: month_label) if month_label.present?
      scope = scope.where(processed_at: @start_date.beginning_of_day..@end_date.end_of_day) unless month_label.present?

      rows = scope.map do |p|
        ded = p.deductions_breakdown.is_a?(Hash) ? p.deductions_breakdown : {}
        emp = p.employee
        {
          employee: emp&.name,
          month: p.month,
          pf: (ded["pf"] || ded["PF"] || 0).to_f.round(2),
          esi: (ded["esi"] || ded["ESI"] || 0).to_f.round(2),
          income_tax: (ded["income_tax"] || ded["tds"] || ded["TDS"] || 0).to_f.round(2),
          professional_tax: (ded["professional_tax"] || ded["pt"] || 0).to_f.round(2),
          total_deductions: ded.values.map { |v| v.to_f }.sum.round(2)
        }
      end

      base_payload(
        title: "Tax & Deduction Report",
        description: "PF, ESI, TDS and other payroll deductions",
        summary: [
          { label: "Payroll records", value: rows.size },
          { label: "Total deductions", value: rows.sum { |r| r[:total_deductions] }.round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("month", "Month"),
          col("pf", "PF", align: "right"),
          col("esi", "ESI", align: "right"),
          col("income_tax", "Income tax", align: "right"),
          col("professional_tax", "Prof. tax", align: "right"),
          col("total_deductions", "Total", align: "right")
        ],
        rows: rows
      )
    end

    def report_bonus_incentives
      structures = SalaryStructure.includes(employee: :department)
                                  .where("bonus > 0")
                                  .where("effective_from <= ?", @end_date)

      rows = structures.map do |s|
        emp = s.employee
        {
          employee: emp&.name,
          department: emp&.department&.name,
          bonus: s.bonus.to_f.round(2),
          monthly_ctc: s.monthly_ctc.to_f.round(2),
          effective_from: s.effective_from&.iso8601
        }
      end

      base_payload(
        title: "Bonus & Incentives",
        description: "Bonus amounts in salary structures",
        summary: [
          { label: "Employees with bonus", value: rows.size },
          { label: "Total bonus", value: rows.sum { |r| r[:bonus] }.round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("bonus", "Bonus", align: "right"),
          col("monthly_ctc", "Monthly CTC", align: "right"),
          col("effective_from", "Effective from")
        ],
        rows: rows
      )
    end

    # --- Leave reports ---

    def report_leave_balance
      year = @params[:year].presence&.to_i || Date.current.year
      rows = []
      active_employees.find_each do |emp|
        LeaveRequest.employee_leave_summary(emp.id, year).each do |bal|
          next if bal[:total].to_i.zero? && bal[:used].to_i.zero?

          rows << {
            employee: emp.name,
            department: emp.department&.name,
            leave_type: bal[:leave_type_label],
            allocated: bal[:total],
            used: bal[:used],
            remaining: bal[:remaining]
          }
        end
      end

      base_payload(
        title: "Leave Balance",
        description: "Employee leave balances for #{year}",
        summary: [ { label: "Balance rows", value: rows.size } ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("leave_type", "Leave type"),
          col("allocated", "Allocated", align: "right"),
          col("used", "Used", align: "right"),
          col("remaining", "Remaining", align: "right")
        ],
        rows: rows
      )
    end

    def report_leave_trends
      leaves = LeaveRequest.approved
                           .where(start_date: @start_date..@end_date)
                           .includes(:employee)

      grouped = leaves.group_by { |l| [ l.start_date.strftime("%Y-%m"), l.leave_type ] }
      rows = grouped.map do |(month, type), reqs|
        {
          month: month,
          leave_type: type.humanize,
          request_count: reqs.size,
          total_days: reqs.sum(&:duration_days)
        }
      end.sort_by { |r| [ r[:month], r[:leave_type] ] }

      base_payload(
        title: "Leave Trends",
        description: "Approved leave patterns by month and type",
        summary: [
          { label: "Approved requests", value: leaves.size },
          { label: "Total leave days", value: leaves.sum(&:duration_days) }
        ],
        columns: [
          col("month", "Month"),
          col("leave_type", "Leave type"),
          col("request_count", "Requests", align: "right"),
          col("total_days", "Days", align: "right")
        ],
        rows: rows
      )
    end

    def report_pending_approvals
      pending = LeaveRequest.where(status: %w[pending manager_approved])
                            .includes(employee: :department)
                            .order(:created_at)

      rows = pending.map do |l|
        {
          employee: l.employee.name,
          department: l.employee.department&.name,
          leave_type: l.leave_type_label,
          start_date: l.start_date.iso8601,
          end_date: l.end_date.iso8601,
          days: l.duration_days,
          status: l.status_label,
          submitted: l.created_at.to_date.iso8601
        }
      end

      base_payload(
        title: "Pending Approvals",
        description: "Leave requests awaiting approval",
        summary: [ { label: "Pending requests", value: rows.size } ],
        columns: [
          col("employee", "Employee"),
          col("department", "Department"),
          col("leave_type", "Type"),
          col("start_date", "Start"),
          col("end_date", "End"),
          col("days", "Days", align: "right"),
          col("status", "Status"),
          col("submitted", "Submitted")
        ],
        rows: rows
      )
    end

    def report_leave_utilization
      leaves = LeaveRequest.approved
                           .where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
                           .includes(employee: :department)

      by_dept = leaves.group_by { |l| l.employee.department&.name || "Unassigned" }
      rows = by_dept.map do |dept, reqs|
        {
          department: dept,
          requests: reqs.size,
          total_days: reqs.sum(&:duration_days),
          employees: reqs.map { |r| r.employee_id }.uniq.size
        }
      end.sort_by { |r| -r[:total_days] }

      base_payload(
        title: "Leave Utilization",
        description: "Department-wise leave usage in the selected period",
        summary: [
          { label: "Departments", value: rows.size },
          { label: "Total leave days", value: rows.sum { |r| r[:total_days] } }
        ],
        columns: [
          col("department", "Department"),
          col("employees", "Employees", align: "right"),
          col("requests", "Requests", align: "right"),
          col("total_days", "Leave days", align: "right")
        ],
        rows: rows
      )
    end

    # --- Performance reports ---

    def report_performance_reviews
      reviews = PerformanceReview.where(review_date: @start_date..@end_date)
                                 .includes(:employee)
                                 .order(review_date: :desc)

      rows = reviews.map do |r|
        {
          employee: r.employee.name,
          period: r.period,
          review_date: r.review_date&.iso8601,
          rating: r.rating.to_f,
          reviewer: r.reviewer
        }
      end

      base_payload(
        title: "Performance Reviews",
        description: "Performance evaluations in the selected period",
        summary: [
          { label: "Reviews completed", value: rows.size },
          { label: "Average rating", value: rows.empty? ? "—" : (rows.sum { |r| r[:rating] } / rows.size).round(2) }
        ],
        columns: [
          col("employee", "Employee"),
          col("period", "Period"),
          col("review_date", "Review date"),
          col("rating", "Rating", align: "right"),
          col("reviewer", "Reviewer")
        ],
        rows: rows
      )
    end

    def report_goal_tracking
      goals = PerformanceGoal.includes(:employee)
                             .where("due_date >= ? OR created_at >= ?", @start_date, @start_date.beginning_of_day)
                             .order(:due_date)

      rows = goals.map do |g|
        {
          employee: g.employee.name,
          title: g.title,
          status: g.status&.humanize,
          progress: "#{g.progress}%",
          due_date: g.due_date&.iso8601,
          target: g.target
        }
      end

      completed = goals.count { |g| g.status == "completed" }
      base_payload(
        title: "Goal Tracking",
        description: "Employee goal progress and status",
        summary: [
          { label: "Active goals", value: rows.size },
          { label: "Completed", value: completed }
        ],
        columns: [
          col("employee", "Employee"),
          col("title", "Goal"),
          col("status", "Status"),
          col("progress", "Progress"),
          col("due_date", "Due date"),
          col("target", "Target")
        ],
        rows: rows
      )
    end

    def report_training_reports
      trainings = EmployeeTraining.includes(:employee)
                                  .where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
                                  .order(:start_date)

      rows = trainings.map do |t|
        {
          employee: t.employee.name,
          training: t.name,
          type: t.training_type&.humanize,
          provider: t.provider,
          status: t.status&.humanize,
          progress: "#{t.progress}%",
          cost: t.cost.to_f.round(2)
        }
      end

      base_payload(
        title: "Training Reports",
        description: "Employee training progress in the selected period",
        summary: [
          { label: "Training records", value: rows.size },
          { label: "Completed", value: trainings.count { |t| t.status == "completed" } }
        ],
        columns: [
          col("employee", "Employee"),
          col("training", "Training"),
          col("type", "Type"),
          col("provider", "Provider"),
          col("status", "Status"),
          col("progress", "Progress"),
          col("cost", "Cost", align: "right")
        ],
        rows: rows
      )
    end

    def report_appraisal_summary
      reviews = PerformanceReview.where(review_date: @start_date..@end_date)
      bands = {
        "Outstanding (4.5+)" => reviews.select { |r| r.rating.to_f >= 4.5 },
        "Exceeds (4.0–4.4)" => reviews.select { |r| v = r.rating.to_f; v >= 4.0 && v < 4.5 },
        "Meets (3.0–3.9)" => reviews.select { |r| v = r.rating.to_f; v >= 3.0 && v < 4.0 },
        "Below (under 3.0)" => reviews.select { |r| r.rating.to_f < 3.0 }
      }

      rows = bands.map do |band, list|
        {
          rating_band: band,
          count: list.size,
          average_rating: list.empty? ? 0 : (list.sum { |r| r.rating.to_f } / list.size).round(2)
        }
      end

      base_payload(
        title: "Appraisal Summary",
        description: "Performance ratings distribution for the period",
        summary: [
          { label: "Total appraisals", value: reviews.size },
          { label: "Average rating", value: reviews.empty? ? "—" : (reviews.sum(&:rating).to_f / reviews.size).round(2) }
        ],
        columns: [
          col("rating_band", "Rating band"),
          col("count", "Count", align: "right"),
          col("average_rating", "Avg rating", align: "right")
        ],
        rows: rows
      )
    end

    # --- Recruitment reports ---

    def report_hiring_pipeline
      candidates = Candidate.not_archived.includes(:job_opening)
      statuses = %w[applied screening interview technical final offered hired rejected]
      grouped = candidates.group_by(&:status)

      rows = statuses.map do |status|
        list = grouped[status] || []
        { stage: status.humanize, count: list.size, percentage: candidates.empty? ? 0 : ((list.size.to_f / candidates.size) * 100).round(1) }
      end

      base_payload(
        title: "Hiring Pipeline",
        description: "Current recruitment funnel by stage",
        summary: [
          { label: "Total candidates", value: candidates.size },
          { label: "Active in pipeline", value: candidates.count { |c| !%w[hired rejected].include?(c.status) } }
        ],
        columns: [
          col("stage", "Stage"),
          col("count", "Candidates", align: "right"),
          col("percentage", "% of total", align: "right")
        ],
        rows: rows
      )
    end

    def report_source_analysis
      candidates = Candidate.not_archived.includes(:job_opening)
      grouped = candidates.group_by { |c| c.job_opening&.title || c.department || "Direct / Unknown" }

      rows = grouped.map do |source, list|
        hired = list.count { |c| c.status == "hired" }
        {
          source: source,
          candidates: list.size,
          hired: hired,
          conversion_rate: list.empty? ? 0 : ((hired.to_f / list.size) * 100).round(1)
        }
      end.sort_by { |r| -r[:candidates] }

      base_payload(
        title: "Source Analysis",
        description: "Candidate volume and conversion by job opening / source",
        summary: [ { label: "Sources tracked", value: rows.size } ],
        columns: [
          col("source", "Source / Job"),
          col("candidates", "Candidates", align: "right"),
          col("hired", "Hired", align: "right"),
          col("conversion_rate", "Conversion %", align: "right")
        ],
        rows: rows
      )
    end

    def report_time_to_hire
      hired = Candidate.where(status: "hired").where(applied_date: @start_date..@end_date).includes(:job_opening)
      rows = hired.map do |c|
        days = (c.updated_at.to_date - c.applied_date).to_i
        {
          candidate: c.full_name,
          position: c.position,
          job_opening: c.job_opening&.title,
          applied_date: c.applied_date.iso8601,
          hired_date: c.updated_at.to_date.iso8601,
          days_to_hire: days
        }
      end.sort_by { |r| r[:days_to_hire] }

      avg = rows.empty? ? 0 : (rows.sum { |r| r[:days_to_hire] }.to_f / rows.size).round(1)

      base_payload(
        title: "Time to Hire",
        description: "Days from application to hire",
        summary: [
          { label: "Hires in period", value: rows.size },
          { label: "Average days to hire", value: avg }
        ],
        columns: [
          col("candidate", "Candidate"),
          col("position", "Position"),
          col("job_opening", "Job opening"),
          col("applied_date", "Applied"),
          col("hired_date", "Hired"),
          col("days_to_hire", "Days", align: "right")
        ],
        rows: rows
      )
    end

    def report_interview_feedback
      interviews = Interview.includes(:candidate)
                            .where(scheduled_date: @start_date..@end_date)
                            .where(status: "completed")
                            .order(scheduled_date: :desc)

      rows = interviews.map do |i|
        {
          candidate: i.candidate&.full_name,
          interview_type: i.interview_type&.humanize,
          date: i.scheduled_date&.iso8601,
          interviewer: i.interviewer,
          rating: i.rating,
          feedback: i.feedback.to_s.truncate(120)
        }
      end

      base_payload(
        title: "Interview Feedback",
        description: "Completed interviews with ratings and feedback",
        summary: [
          { label: "Interviews completed", value: rows.size },
          { label: "Average rating", value: rows.empty? ? "—" : (rows.sum { |r| r[:rating].to_i } / rows.size.to_f).round(2) }
        ],
        columns: [
          col("candidate", "Candidate"),
          col("interview_type", "Type"),
          col("date", "Date"),
          col("interviewer", "Interviewer"),
          col("rating", "Rating", align: "right"),
          col("feedback", "Feedback")
        ],
        rows: rows
      )
    end
  end
end
