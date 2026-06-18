# frozen_string_literal: true

class AddCompanyIdToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :company, foreign_key: true

    say_with_time "Backfilling users.company_id" do
      default_company = Company.order(:id).first
      User.where(company_id: nil).update_all(company_id: default_company.id) if default_company
    end
  end

  def down
    remove_reference :users, :company, foreign_key: true
  end
end
