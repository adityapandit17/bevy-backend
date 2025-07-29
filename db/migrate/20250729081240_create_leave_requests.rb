class CreateLeaveRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :leave_requests do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :leave_type
      t.date :start_date
      t.date :end_date
      t.text :reason
      t.string :status

      t.timestamps
    end
  end
end
