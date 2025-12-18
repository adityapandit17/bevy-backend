class AddCtcToSalaryStructures < ActiveRecord::Migration[8.1]
  def change
    add_column :salary_structures, :annual_ctc, :decimal, precision: 10, scale: 2, default: 0
    add_column :salary_structures, :monthly_ctc, :decimal, precision: 10, scale: 2, default: 0
  end
end
