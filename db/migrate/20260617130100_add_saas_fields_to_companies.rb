# frozen_string_literal: true

class AddSaasFieldsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :status, :string, null: false, default: "active"
    add_column :companies, :plan, :string, null: false, default: "starter"
    add_column :companies, :trial_ends_at, :datetime
    add_column :companies, :max_employees, :integer, default: 50
    add_column :companies, :contact_email, :string
    add_column :companies, :contact_name, :string
  end
end
