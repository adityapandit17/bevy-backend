class CreateRecognitions < ActiveRecord::Migration[8.1]
  def change
    create_table :recognitions do |t|
      t.references :given_by, null: false, foreign_key: { to_table: :users }, index: true
      t.references :received_by, null: false, foreign_key: { to_table: :employees }, index: true
      t.string :recognition_type, null: false
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :status, default: "active"

      t.timestamps
    end

    add_index :recognitions, :recognition_type
    add_index :recognitions, :status
    add_index :recognitions, :created_at
  end
end
