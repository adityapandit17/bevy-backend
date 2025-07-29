class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :code
      t.string :industry
      t.string :employee_count
      t.text :address
      t.string :timezone
      t.string :currency

      t.timestamps
    end
  end
end
