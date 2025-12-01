class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.boolean :read, null: false, default: false
      t.string :action_url

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, :notification_type
    add_index :notifications, :created_at
  end
end


