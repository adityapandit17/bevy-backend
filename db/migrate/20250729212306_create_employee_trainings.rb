class CreateEmployeeTrainings < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_trainings do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :name
      t.string :training_type
      t.string :provider
      t.date :start_date
      t.date :end_date
      t.string :status
      t.integer :progress
      t.string :certificate
      t.decimal :cost
      t.text :skills

      t.timestamps
    end
  end
end
