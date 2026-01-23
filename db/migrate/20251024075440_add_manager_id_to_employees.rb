class AddManagerIdToEmployees < ActiveRecord::Migration[8.0]
  def change
    # Only add the column if it doesn't already exist
    # (The employees table was created with manager_id via t.references :manager)
    add_column :employees, :manager_id, :integer unless column_exists?(:employees, :manager_id)
  end
end
