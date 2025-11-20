class CreateAttendanceSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_sessions do |t|
      t.references :attendance_record, null: false, foreign_key: true
      t.datetime :check_in
      t.datetime :check_out
      t.decimal :session_hours, precision: 5, scale: 2

      t.timestamps
    end
  end
end
