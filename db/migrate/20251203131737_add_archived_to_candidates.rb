class AddArchivedToCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :candidates, :archived, :boolean, default: false, null: false
    add_index :candidates, :archived
  end
end
