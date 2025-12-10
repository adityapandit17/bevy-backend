class AddAdditionalFieldsToSalaryStructures < ActiveRecord::Migration[8.0]
  def change
    add_reference :salary_structures, :department, foreign_key: true, null: true
    add_column :salary_structures, :level, :string
    add_column :salary_structures, :bonus, :decimal, precision: 10, scale: 2, default: 0
    add_column :salary_structures, :pf, :decimal, precision: 10, scale: 2, default: 0
    add_column :salary_structures, :esi, :decimal, precision: 10, scale: 2, default: 0
    add_column :salary_structures, :professional_tax, :decimal, precision: 10, scale: 2, default: 0
    add_column :salary_structures, :income_tax, :decimal, precision: 10, scale: 2, default: 0
  end
end

