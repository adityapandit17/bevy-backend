# frozen_string_literal: true

class CreatePlatformSaasTables < ActiveRecord::Migration[8.1]
  def change
    create_table :pricing_plans do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.integer :monthly_price, default: 0, null: false
      t.integer :annual_price, default: 0, null: false
      t.integer :max_employees, default: 50, null: false
      t.jsonb :features, default: [], null: false
      t.boolean :published, default: true, null: false
      t.boolean :popular, default: false, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :pricing_plans, :slug, unique: true

    create_table :platform_inquiries do |t|
      t.string :company_name, null: false
      t.string :contact_name, null: false
      t.string :email, null: false
      t.string :source, default: "website"
      t.string :plan_interest, default: "starter"
      t.integer :estimated_seats, default: 10
      t.string :assignee
      t.string :status, default: "new", null: false
      t.text :notes

      t.timestamps
    end
    add_index :platform_inquiries, :status
    add_index :platform_inquiries, :email

    create_table :platform_follow_ups do |t|
      t.references :platform_inquiry, null: false, foreign_key: true
      t.string :company_name, null: false
      t.string :assignee, null: false
      t.date :due_date, null: false
      t.string :status, default: "scheduled", null: false
      t.string :follow_up_type, default: "call", null: false
      t.text :notes

      t.timestamps
    end
    add_index :platform_follow_ups, :status
    add_index :platform_follow_ups, :due_date

    create_table :platform_campaigns do |t|
      t.string :name, null: false
      t.string :channel, default: "email", null: false
      t.string :audience
      t.string :status, default: "draft", null: false
      t.integer :sent_count, default: 0, null: false
      t.integer :conversions, default: 0, null: false
      t.integer :budget, default: 0, null: false
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    add_index :platform_campaigns, :status

    create_table :platform_announcements do |t|
      t.string :title, null: false
      t.text :message, null: false
      t.string :audience, default: "all", null: false
      t.string :status, default: "draft", null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.references :platform_admin_user, foreign_key: true

      t.timestamps
    end
    add_index :platform_announcements, :status

    create_table :company_feature_flags do |t|
      t.references :company, null: false, foreign_key: true
      t.string :key, null: false
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end
    add_index :company_feature_flags, [ :company_id, :key ], unique: true

    create_table :platform_invoices do |t|
      t.references :company, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.integer :amount, default: 0, null: false
      t.string :status, default: "draft", null: false
      t.date :billing_period_start
      t.date :billing_period_end
      t.date :due_date
      t.datetime :paid_at
      t.string :plan
      t.text :notes

      t.timestamps
    end
    add_index :platform_invoices, :invoice_number, unique: true
    add_index :platform_invoices, :status

    create_table :subscription_requests do |t|
      t.references :company, foreign_key: true
      t.string :company_name
      t.string :request_type, default: "new_tenant", null: false
      t.string :plan, default: "starter", null: false
      t.integer :seats, default: 10
      t.integer :amount, default: 0
      t.string :billing_cycle, default: "monthly", null: false
      t.string :status, default: "pending", null: false
      t.string :requested_by
      t.text :notes

      t.timestamps
    end
    add_index :subscription_requests, :status

    create_table :platform_settings do |t|
      t.string :key, null: false
      t.text :value

      t.timestamps
    end
    add_index :platform_settings, :key, unique: true

    change_table :companies, bulk: true do |t|
      t.string :billing_cycle, default: "monthly", null: false
      t.datetime :renews_at
    end
  end
end
