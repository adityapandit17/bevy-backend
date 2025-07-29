class CreateOnboardingTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding_tasks do |t|
      t.references :onboarding_employee, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :category
      t.string :priority
      t.date :due_date
      t.string :assigned_to
      t.boolean :is_completed
      t.text :documents

      t.timestamps
    end
  end
end
