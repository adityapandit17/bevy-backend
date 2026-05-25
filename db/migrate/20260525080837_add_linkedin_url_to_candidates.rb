class AddLinkedinUrlToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :linkedin_url, :string
  end
end
