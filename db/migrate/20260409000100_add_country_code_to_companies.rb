class AddCountryCodeToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :country_code, :string
    add_index :companies, :country_code
  end
end
