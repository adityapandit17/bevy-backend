class CreatePerformanceGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :performance_goals do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :target
      t.integer :progress
      t.string :status
      t.date :due_date

      t.timestamps
    end
  end
end
