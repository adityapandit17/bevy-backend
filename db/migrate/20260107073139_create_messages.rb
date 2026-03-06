class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.datetime :edited_at

      t.timestamps
    end
    add_index :messages, [ :channel_id, :created_at ]
  end
end
