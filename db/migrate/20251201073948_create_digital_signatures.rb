class CreateDigitalSignatures < ActiveRecord::Migration[8.1]
  def change
    create_table :digital_signatures do |t|
      t.references :policy_document, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :signed_date
      t.string :status, default: "pending"
      t.string :signature_type
      t.string :ip_address
      t.text :device_info
      t.text :user_agent

      t.timestamps
    end

    add_index :digital_signatures, :status
    add_index :digital_signatures, :signed_date
    add_index :digital_signatures, [ :policy_document_id, :employee_id ], unique: true, name: "index_digital_signatures_on_policy_and_employee"
  end
end
