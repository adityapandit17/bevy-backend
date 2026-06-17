# frozen_string_literal: true

class AddDashboardLayoutToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :dashboard_layout, :string, default: "top_nav", null: false
  end
end
