class AddApprovalFieldsToLeaveRequests < ActiveRecord::Migration[8.0]
  def change
    add_reference :leave_requests, :manager_approved_by, foreign_key: { to_table: :users }
    add_column :leave_requests, :manager_approved_at, :datetime
    add_reference :leave_requests, :hr_approved_by, foreign_key: { to_table: :users }
    add_column :leave_requests, :hr_approved_at, :datetime
    add_reference :leave_requests, :rejected_by, foreign_key: { to_table: :users }
    add_column :leave_requests, :rejected_reason, :text
    add_column :leave_requests, :rejected_at, :datetime
  end
end


