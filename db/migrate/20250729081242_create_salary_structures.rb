class CreateSalaryStructures < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_structures do |t|
      t.references :employee, null: false, foreign_key: true
      t.decimal :basic
      t.decimal :hra
      t.decimal :allowances
      t.decimal :deductions
      t.date :effective_from

      t.timestamps
    end
  end
end
