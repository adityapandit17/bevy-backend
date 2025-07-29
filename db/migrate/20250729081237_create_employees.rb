class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.references :department, null: false, foreign_key: true
      t.string :designation
      t.date :date_of_joining
      t.string :status

      t.timestamps
    end
    add_index :employees, :email, unique: true
  end
end
