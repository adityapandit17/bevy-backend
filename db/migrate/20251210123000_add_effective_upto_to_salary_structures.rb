class AddEffectiveUptoToSalaryStructures < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_structures, :effective_upto, :date
  end
end

