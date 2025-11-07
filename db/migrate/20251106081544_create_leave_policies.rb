class CreateLeavePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_policies do |t|
      t.integer :year
      t.integer :holidays_per_year
      t.integer :annual_leave
      t.integer :sick_leave
      t.integer :personal_leave
      t.integer :maternity_leave
      t.integer :paternity_leave
      t.integer :unpaid_leave
      t.integer :other_leave
      t.boolean :active

      t.timestamps
    end
  end
end
