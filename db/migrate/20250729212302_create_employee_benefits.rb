class CreateEmployeeBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_benefits do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :name
      t.string :benefit_type
      t.string :provider
      t.string :coverage
      t.date :start_date
      t.date :end_date
      t.string :status
      t.decimal :cost

      t.timestamps
    end
  end
end
