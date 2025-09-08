class AddDateOfBirthToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :date_of_birth, :date
  end
end
