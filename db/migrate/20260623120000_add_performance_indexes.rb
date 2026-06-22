class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :employees, [ :company_id, :status ], name: "index_employees_on_company_id_and_status", if_not_exists: true
    add_index :employees, :manager_id, if_not_exists: true
    add_index :attendance_records, [ :company_id, :date, :status ],
              name: "index_attendance_records_on_company_date_status", if_not_exists: true
    add_index :leave_requests, [ :status, :start_date, :end_date ],
              name: "index_leave_requests_on_status_and_dates", if_not_exists: true
    add_index :payrolls, [ :company_id, :month, :status ],
              name: "index_payrolls_on_company_month_status", if_not_exists: true
    add_index :pending_tasks, [ :assigned_to_id, :status, :taskable_type ],
              name: "index_pending_tasks_on_assignee_status_type", if_not_exists: true
  end
end
