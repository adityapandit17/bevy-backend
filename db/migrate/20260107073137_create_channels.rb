class CreateChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :channels do |t|
      t.string :name, null: false
      t.string :channel_type, null: false, default: "channel"
      t.boolean :is_private, default: false, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :description

      t.timestamps
    end
    add_index :channels, :channel_type
    add_index :channels, :name
    add_index :channels, [ :channel_type, :name ]
  end
end
