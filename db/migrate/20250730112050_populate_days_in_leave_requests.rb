class PopulateDaysInLeaveRequests < ActiveRecord::Migration[8.0]
  def up
    # Add hours column to employee_trainings if it doesn't exist
    unless column_exists?(:employee_trainings, :hours)
      add_column :employee_trainings, :hours, :integer, default: 0
    end
    
    # Populate days for existing leave requests
    LeaveRequest.find_each do |leave_request|
      if leave_request.start_date && leave_request.end_date
        days = (leave_request.end_date - leave_request.start_date).to_i + 1
        leave_request.update_column(:days, days)
      end
    end
    
    # Populate hours for existing employee trainings
    EmployeeTraining.find_each do |training|
      if training.start_date && training.end_date
        # Calculate hours based on duration (assuming 8 hours per day)
        days = (training.end_date - training.start_date).to_i + 1
        hours = days * 8
        training.update_column(:hours, hours)
      end
    end
  end

  def down
    LeaveRequest.update_all(days: nil)
    EmployeeTraining.update_all(hours: nil)
    remove_column :employee_trainings, :hours if column_exists?(:employee_trainings, :hours)
  end
end
