class CreateHuddles < ActiveRecord::Migration[8.1]
  def change
    create_table :huddles do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :started_by, null: false, foreign_key: { to_table: :users }
      t.string :status, default: "active", null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.timestamps
    end

    add_index :huddles, :status
    add_index :huddles, :started_at
    add_index :huddles, [:channel_id, :status]
  end
end
