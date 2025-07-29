class RenameTypeToJobTypeInJobOpenings < ActiveRecord::Migration[8.0]
  def change
    rename_column :job_openings, :type, :job_type
  end
end
