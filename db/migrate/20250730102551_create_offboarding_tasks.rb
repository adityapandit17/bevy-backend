class CreateOffboardingTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :offboarding_tasks do |t|
      t.references :offboarding_employee, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :category
      t.string :priority
      t.date :due_date
      t.string :assigned_to
      t.boolean :is_completed
      t.date :completed_date
      t.text :documents

      t.timestamps
    end
  end
end
