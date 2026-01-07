class CreateChannelMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_memberships do |t|
      t.references :channel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, default: "member", null: false
      t.datetime :last_read_at

      t.timestamps
    end
    add_index :channel_memberships, [:channel_id, :user_id], unique: true
  end
end
