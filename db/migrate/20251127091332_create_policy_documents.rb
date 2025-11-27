class CreatePolicyDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :policy_documents do |t|
      t.string :title, null: false
      t.string :category, null: false
      t.string :version
      t.string :file_path, null: false
      t.integer :file_size, default: 0
      t.date :last_updated
      t.date :expiry_date
      t.string :status, default: "active"
      t.integer :downloads, default: 0
      t.boolean :requires_signature, default: false
      t.integer :uploaded_by

      t.timestamps
    end
    
    add_index :policy_documents, :category
    add_index :policy_documents, :status
  end
end
