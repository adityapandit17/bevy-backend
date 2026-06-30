# frozen_string_literal: true

class AddCompanyIdToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :company, foreign_key: true

    say_with_time "Backfilling users.company_id" do
      default_company_id = execute("SELECT id FROM companies ORDER BY id ASC LIMIT 1").first&.fetch("id")
      User.where(company_id: nil).update_all(company_id: default_company_id) if default_company_id
    end
  end

  def down
    remove_reference :users, :company, foreign_key: true
  end
end
