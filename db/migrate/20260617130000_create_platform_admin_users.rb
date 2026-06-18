# frozen_string_literal: true

class CreatePlatformAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_admin_users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :role, null: false, default: "super_admin"
      t.string :status, null: false, default: "active"
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :platform_admin_users, :email, unique: true
  end
end
