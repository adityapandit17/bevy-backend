class AddFilePathToEmployeeDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :employee_documents, :file_path, :string
  end
end
