class RemoveCheckInOutFromAttendanceRecords < ActiveRecord::Migration[8.1]
  def change
    remove_column :attendance_records, :check_in, :time
    remove_column :attendance_records, :check_out, :time
  end
end
