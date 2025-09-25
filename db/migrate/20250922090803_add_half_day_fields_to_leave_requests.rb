class AddHalfDayFieldsToLeaveRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :leave_requests, :half_day, :boolean
    add_column :leave_requests, :half_day_period, :string
    add_column :leave_requests, :emergency_contact, :string
    add_column :leave_requests, :handover_notes, :text
  end
end
