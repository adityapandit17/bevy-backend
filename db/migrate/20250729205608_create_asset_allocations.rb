class CreateAssetAllocations < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_allocations do |t|
      t.references :asset, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :assigned_date
      t.date :return_date
      t.text :notes
      t.string :status

      t.timestamps
    end
  end
end
