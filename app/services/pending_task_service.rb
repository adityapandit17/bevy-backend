class PendingTaskService
  def self.sync_leave_request(leave_request)
    # Only create pending tasks for pending leave requests
    if leave_request.pending?
      # Find the manager who should approve this leave request
      manager = leave_request.employee.manager

      if manager
        # Create or update pending task for the manager
        pending_task = PendingTask.find_or_initialize_by(
          taskable: leave_request,
          assigned_to_id: manager.id
        )

        pending_task.assign_attributes(
          title: "Review Leave Application - #{leave_request.employee.name}",
          priority: "high",
          due_date: Date.current,
          status: "pending"
        )

        pending_task.save
      end

      # Also create pending tasks for HR/Admin users if needed
      # This can be expanded based on your business logic
      if should_create_hr_task?(leave_request)
        create_hr_pending_task(leave_request)
      end
    else
      # If leave request is no longer pending, mark all related pending tasks as completed
      leave_request.pending_tasks.pending.each(&:mark_completed!)
    end
  end

  def self.sync_interview(interview)
    # Only create pending tasks for scheduled interviews
    if interview.status == "scheduled"
      # Find the employee who is the interviewer
      # Since name is a method (first_name + last_name), use SQL to match
      interviewer_employee = Employee.where(
        "LOWER(TRIM(first_name || ' ' || last_name)) = ?",
        interview.interviewer&.downcase&.strip
      ).first

      if interviewer_employee
        # Determine if it's overdue or upcoming
        if interview.is_overdue?
          title = "Missed Interview - #{interview.candidate.name}"
          priority = "high"
          due_date = interview.scheduled_date
        else
          title = "Interview Scheduled - #{interview.candidate.name}"
          priority = "medium"
          due_date = interview.scheduled_date
        end

        # Create or update pending task
        pending_task = PendingTask.find_or_initialize_by(
          taskable: interview,
          assigned_to_id: interviewer_employee.id
        )

        pending_task.assign_attributes(
          title: title,
          priority: priority,
          due_date: due_date,
          status: "pending"
        )

        pending_task.save
      end
    else
      # If interview is no longer scheduled, mark all related pending tasks as completed
      interview.pending_tasks.pending.each(&:mark_completed!)
    end
  end

  def self.should_create_hr_task?(leave_request)
    # Add logic here if HR should also get pending tasks
    # For now, we'll rely on the manager task and the dashboard logic
    false
  end

  def self.create_hr_pending_task(leave_request)
    # This can be implemented if HR needs separate pending tasks
    # For now, we'll use the manager's pending task
  end

  # Method to sync all existing records (for data migration)
  def self.sync_all_leave_requests
    LeaveRequest.pending.find_each do |leave_request|
      sync_leave_request(leave_request)
    end
  end

  def self.sync_all_interviews
    Interview.scheduled.find_each do |interview|
      sync_interview(interview)
    end
  end
end
