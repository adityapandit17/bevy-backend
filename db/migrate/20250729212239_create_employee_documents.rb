class CreateEmployeeDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_documents do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :name
      t.string :document_type
      t.date :upload_date
      t.date :expiry_date
      t.string :status
      t.string :file_size
      t.string :uploaded_by

      t.timestamps
    end
  end
end
