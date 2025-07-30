class CreateOffboardingEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :offboarding_employees do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :last_working_day
      t.string :status
      t.integer :progress
      t.string :assigned_to
      t.text :notes
      t.date :start_date

      t.timestamps
    end
  end
end
