# frozen_string_literal: true

class CreateHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :holidays do |t|
      t.references :company, null: false, foreign_key: true
      t.date :date, null: false
      t.string :name, null: false
      t.text :reason
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :holidays, [ :company_id, :date ], unique: true
  end
end
