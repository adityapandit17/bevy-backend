class DashboardController < ApplicationController
  before_action :authenticate_user!

  # GET /dashboard
  def index
    begin
      @stats = {
        total_employees: Employee.active.size,
        present_today: attendance_stats[:present],
        on_leave: attendance_stats[:on_leave],
        monthly_payroll: payroll_stats[:total_amount]
      }

      @recent_activities = recent_activities
      @upcoming_events = upcoming_events
      @birthdays_today = birthdays_today
      @upcoming_birthdays = upcoming_birthdays
      @pending_tasks = pending_tasks

      render json: {
        stats: @stats,
        recent_activities: @recent_activities,
        upcoming_events: @upcoming_events,
        birthdays_today: @birthdays_today,
        upcoming_birthdays: @upcoming_birthdays,
        pending_tasks: @pending_tasks
      }
    rescue => e
      Rails.logger.error "Dashboard error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def attendance_stats
    today = Date.current
    present_count = AttendanceRecord.joins(:employee)
                                   .where(date: today, status: "present")
                                   .where(employees: { status: "active" })
                                   .size

    on_leave_count = LeaveRequest.joins(:employee)
                                 .where("start_date <= ? AND end_date >= ?", today, today)
                                 .where(status: "approved")
                                 .where(employees: { status: "active" })
                                 .size

    {
      present: present_count,
      on_leave: on_leave_count
    }
  end

  def payroll_stats
    current_month = Date.current.strftime("%B %Y")
    total_amount = Payroll.where(month: current_month, status: "processed").sum(:net_salary)

    {
      total_amount: total_amount
    }
  end

  def recent_activities
    activities = []

    # Recent employee additions - include both active and onboarding employees
    recent_employees = Employee.where(status: ["active", "onboarding"])
                              .where("employees.created_at >= ?", 7.days.ago)
                              .order(created_at: :desc)
                              .limit(3)
    recent_employees.each do |employee|
      activities << {
        id: "employee_#{employee.id}",
        type: "New Employee",
        description: "#{employee.name} joined as #{employee.designation}",
        time: time_ago_in_words(employee.created_at) + " ago",
        status: "success",
        created_at: employee.created_at
      }
    end

    # Recent leave requests
    recent_leaves = LeaveRequest.joins(:employee)
                               .where("leave_requests.created_at >= ?", 7.days.ago)
                               .where(employees: { status: "active" })
                               .order(created_at: :desc)
                               .limit(2)
    recent_leaves.each do |leave|
      activities << {
        id: "leave_#{leave.id}",
        type: "Leave Request",
        description: "#{leave.employee.name} requested #{leave.leave_type} leave",
        time: time_ago_in_words(leave.created_at) + " ago",
        status: leave.status == "approved" ? "success" : "pending",
        created_at: leave.created_at
      }
    end

    # Recent performance reviews
    recent_reviews = PerformanceReview.joins(:employee)
                                     .where("performance_reviews.created_at >= ?", 7.days.ago)
                                     .where(employees: { status: "active" })
                                     .order(created_at: :desc)
                                     .limit(2)
    recent_reviews.each do |review|
      activities << {
        id: "review_#{review.id}",
        type: "Performance Review",
        description: "Q3 reviews completed for #{review.employee.department.name} team",
        time: time_ago_in_words(review.created_at) + " ago",
        status: "success",
        created_at: review.created_at
      }
    end

    # Sort by created_at timestamp (most recent first) and limit to 5
    activities.sort_by { |activity| activity[:created_at] }.reverse.first(5).map { |a| a.except(:created_at) }
  end

  def upcoming_events
    events = []

    # Team building events (mock data for now)
    events << {
      id: 1,
      title: "Team Building Event",
      date: "Nov 15, 2024",
      time: "10:00 AM",
      attendees: 45
    }

    events << {
      id: 2,
      title: "Performance Review Meeting",
      date: "Nov 18, 2024",
      time: "2:00 PM",
      attendees: 12
    }

    events << {
      id: 3,
      title: "New Employee Orientation",
      date: "Nov 20, 2024",
      time: "9:00 AM",
      attendees: 8
    }

    events
  end

  def birthdays_today
    Employee.active.birthday_today.includes(:department).map do |employee|
      {
        id: employee.id,
        name: employee.name,
        department: employee.department.name,
        designation: employee.designation,
        age: employee.age,
        avatar: employee.avatar_url
      }
    end
  end

  def upcoming_birthdays
    upcoming = []

    # Get birthdays for the next 7 days
    (1..7).each do |day_offset|
      date = Date.current + day_offset.days
      birthdays_on_date = Employee.active.where(
        "strftime('%m-%d', date_of_birth) = ?",
        date.strftime("%m-%d")
      ).includes(:department)

      birthdays_on_date.each do |employee|
        upcoming << {
          id: employee.id,
          name: employee.name,
          department: employee.department.name,
          designation: employee.designation,
          birthday: day_offset == 1 ? "Tomorrow" : date.strftime("%b %d"),
          daysUntil: day_offset,
          avatar: employee.avatar_url
        }
      end
    end

    upcoming.first(4) # Limit to 4 upcoming birthdays
  end

  def pending_tasks
    return [] unless current_user&.employee

    employee_id = current_user.employee.id
    tasks = []

    # Get pending leave approvals for this manager
    pending_leaves = PendingTask.pending
                                 .by_type("LeaveRequest")
                                 .for_employee(employee_id)
                                 .count
    # For HR/Admin users who are NOT managers (no direct reports), show all pending leaves
    is_admin_or_hr = current_user.has_role?("Super Admin") ||
                     current_user.has_role?("HR Manager") ||
                     current_user.has_role?("HR") ||
                     current_user.has_permission?("leave_requests", "index")

    # Check if user has direct reports
    has_direct_reports = current_user.employee.direct_reports.active.exists?

    # Only show all pending leaves if user is HR/Admin AND has no direct reports
    # This ensures managers see their direct reports first, HR/Admin without direct reports see all
    if is_admin_or_hr && !has_direct_reports && pending_leaves == 0
      # HR/Admin with no direct reports see all pending leaves
      pending_leaves = PendingTask.pending
                                   .by_type("LeaveRequest")
                                   .joins("INNER JOIN leave_requests ON pending_tasks.taskable_id = leave_requests.id")
                                   .joins("INNER JOIN employees ON leave_requests.employee_id = employees.id")
                                   .where("employees.status = ?", "active")
                                   .distinct
                                   .count
    end

    if pending_leaves > 0
      tasks << {
        id: 1,
        title: "Review Leave Applications",
        count: pending_leaves,
        priority: "high",
        dueDate: "Today"
      }
    end

    # Scheduled interviews assigned to current employee
    scheduled_interviews = PendingTask.pending
                                      .by_type("Interview")
                                      .for_employee(employee_id)
                                      .where("title LIKE ?", "%Interview Scheduled%")
                                      .where("due_date >= ?", Date.current)
                                      .count
    if scheduled_interviews > 0
      tasks << {
        id: 4,
        title: "Interview Scheduled",
        count: scheduled_interviews,
        priority: "medium",
        dueDate: "Upcoming"
      }
    end

    # Missed interviews assigned to current employee
    missed_interviews = PendingTask.pending
                                   .by_type("Interview")
                                   .for_employee(employee_id)
                                   .where("title LIKE ?", "%Interview%")
                                   .where("due_date < ?", Date.current)
                                   .count

    if missed_interviews > 0
      tasks << {
        id: 5,
        title: "Missed Interviews",
        count: missed_interviews,
        priority: "high",
        dueDate: "Overdue"
      }
    end

    tasks
  end

  def time_ago_in_words(time)
    distance = Time.current - time

    case distance
    when 0..1.minute
      "less than a minute"
    when 1.minute..59.minutes
      "#{(distance / 1.minute).round} minutes"
    when 1.hour..23.hours
      "#{(distance / 1.hour).round} hours"
    when 1.day..29.days
      "#{(distance / 1.day).round} days"
    when 1.month..11.months
      "#{(distance / 1.month).round} months"
    else
      "#{(distance / 1.year).round} years"
    end
  end
end
