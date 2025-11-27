class PopulatePendingTasks < ActiveRecord::Migration[8.1]
  def up
    # Populate pending tasks for existing pending leave requests
    LeaveRequest.pending.find_each do |leave_request|
      next unless leave_request.employee&.manager

      PendingTask.find_or_create_by(
        taskable: leave_request,
        assigned_to_id: leave_request.employee.manager.id
      ) do |task|
        task.title = "Review Leave Application - #{leave_request.employee.name}"
        task.priority = "high"
        task.due_date = Date.current
        task.status = "pending"
      end
    end

    # Populate pending tasks for existing scheduled interviews
    Interview.scheduled.find_each do |interview|
      # Try to find employee by matching first_name + last_name or first_name || ' ' || last_name
      # Since name is a method, we need to use SQL to match
      interviewer_employee = Employee.where(
        "LOWER(TRIM(first_name || ' ' || last_name)) = ?",
        interview.interviewer&.downcase&.strip
      ).first
      next unless interviewer_employee

      if interview.is_overdue?
        title = "Missed Interview - #{interview.candidate.name}"
        priority = "high"
      else
        title = "Interview Scheduled - #{interview.candidate.name}"
        priority = "medium"
      end

      PendingTask.find_or_create_by(
        taskable: interview,
        assigned_to_id: interviewer_employee.id
      ) do |task|
        task.title = title
        task.priority = priority
        task.due_date = interview.scheduled_date
        task.status = "pending"
      end
    end
  end

  def down
    # Remove all pending tasks (optional - you may want to keep them)
    PendingTask.destroy_all
  end
end
