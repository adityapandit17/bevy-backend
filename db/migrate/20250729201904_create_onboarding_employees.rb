class CreateOnboardingEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding_employees do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :start_date
      t.string :status
      t.integer :progress
      t.text :notes

      t.timestamps
    end
  end
end
