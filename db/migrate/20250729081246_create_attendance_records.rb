class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :date
      t.string :status
      t.time :check_in
      t.time :check_out

      t.timestamps
    end
  end
end
