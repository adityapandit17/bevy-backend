class AddBadgeLevelToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :badge_level, :string
    add_index :employees, :badge_level
  end
end
