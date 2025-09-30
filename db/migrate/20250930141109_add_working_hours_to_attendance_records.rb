class AddWorkingHoursToAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :attendance_records, :working_hours, :decimal
  end
end
