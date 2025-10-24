class AddManagerIdToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :manager_id, :integer
  end
end
