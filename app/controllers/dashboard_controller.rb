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

    # Recent employee additions
    recent_employees = Employee.active.where("employees.created_at >= ?", 7.days.ago).limit(3)
    recent_employees.each do |employee|
      activities << {
        id: "employee_#{employee.id}",
        type: "New Employee",
        description: "#{employee.name} joined as #{employee.designation}",
        time: time_ago_in_words(employee.created_at) + " ago",
        status: "success"
      }
    end

    # Recent leave requests
    recent_leaves = LeaveRequest.joins(:employee)
                               .where("leave_requests.created_at >= ?", 7.days.ago)
                               .where(employees: { status: "active" })
                               .limit(2)
    recent_leaves.each do |leave|
      activities << {
        id: "leave_#{leave.id}",
        type: "Leave Request",
        description: "#{leave.employee.name} requested #{leave.leave_type} leave",
        time: time_ago_in_words(leave.created_at) + " ago",
        status: leave.status == "approved" ? "success" : "pending"
      }
    end

    # Recent performance reviews
    recent_reviews = PerformanceReview.joins(:employee)
                                     .where("performance_reviews.created_at >= ?", 7.days.ago)
                                     .where(employees: { status: "active" })
                                     .limit(2)
    recent_reviews.each do |review|
      activities << {
        id: "review_#{review.id}",
        type: "Performance Review",
        description: "Q3 reviews completed for #{review.employee.department.name} team",
        time: time_ago_in_words(review.created_at) + " ago",
        status: "success"
      }
    end

    activities.sort_by { |activity| activity[:time] }.first(5)
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
    tasks = []

    # Pending leave approvals
    pending_leaves = LeaveRequest.joins(:employee)
                                .where(leave_requests: { status: "pending" })
                                .where(employees: { status: "active" })
                                .size
    if pending_leaves > 0
      tasks << {
        id: 1,
        title: "Review Leave Applications",
        count: pending_leaves,
        priority: "high",
        dueDate: "Today"
      }
    end

    # Pending timesheet approvals
    pending_timesheets = Timesheet.joins(:employee)
                                 .where(timesheets: { status: "pending" })
                                 .where(employees: { status: "active" })
                                 .size
    if pending_timesheets > 0
      tasks << {
        id: 2,
        title: "Approve Timesheets",
        count: pending_timesheets,
        priority: "medium",
        dueDate: "Tomorrow"
      }
    end

    # Pending performance reviews
    pending_reviews = PerformanceReview.joins(:employee)
                                      .where("performance_reviews.review_date <= ?", Date.current)
                                      .where(employees: { status: "active" })
                                      .size
    if pending_reviews > 0
      tasks << {
        id: 3,
        title: "Complete Performance Reviews",
        count: pending_reviews,
        priority: "high",
        dueDate: "This Week"
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
