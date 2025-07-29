class CreatePayrolls < ActiveRecord::Migration[8.0]
  def change
    create_table :payrolls do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :month
      t.decimal :gross_salary
      t.decimal :net_salary
      t.string :status

      t.timestamps
    end
  end
end
