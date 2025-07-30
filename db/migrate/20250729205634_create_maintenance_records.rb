class CreateMaintenanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_records do |t|
      t.references :asset, null: false, foreign_key: true
      t.date :maintenance_date
      t.string :maintenance_type
      t.text :description
      t.decimal :cost
      t.string :performed_by
      t.date :next_maintenance

      t.timestamps
    end
  end
end
