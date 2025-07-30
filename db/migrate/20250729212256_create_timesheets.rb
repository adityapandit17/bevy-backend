class CreateTimesheets < ActiveRecord::Migration[8.0]
  def change
    create_table :timesheets do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :date
      t.decimal :hours
      t.string :project
      t.string :task
      t.string :status
      t.string :approved_by
      t.text :notes

      t.timestamps
    end
  end
end
