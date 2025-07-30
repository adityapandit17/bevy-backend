class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :name
      t.string :asset_type
      t.string :serial_number
      t.string :model
      t.string :brand
      t.date :purchase_date
      t.date :warranty_expiry
      t.decimal :purchase_cost
      t.decimal :current_value
      t.string :status
      t.string :location
      t.string :department
      t.text :notes
      t.string :condition
      t.date :last_maintenance
      t.date :next_maintenance
      t.references :employee, null: true, foreign_key: true

      t.timestamps
    end
  end
end
