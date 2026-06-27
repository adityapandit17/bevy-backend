# frozen_string_literal: true

class CreatePlatformAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_audit_logs do |t|
      t.references :platform_admin_user, null: false, foreign_key: true
      t.references :company, foreign_key: true
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.jsonb :metadata, default: {}, null: false
      t.string :ip_address

      t.timestamps
    end

    add_index :platform_audit_logs, [ :company_id, :created_at ]
    add_index :platform_audit_logs, [ :platform_admin_user_id, :created_at ]
    add_index :platform_audit_logs, [ :resource_type, :resource_id ]
    add_index :platform_audit_logs, :action
    add_index :platform_audit_logs, :created_at
  end
end
