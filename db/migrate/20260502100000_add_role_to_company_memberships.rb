# frozen_string_literal: true

class AddRoleToCompanyMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :company_memberships, :role, :string
  end
end
