class AddFieldsToJobOpenings < ActiveRecord::Migration[8.0]
  def change
    add_column :job_openings, :requirements, :string
    add_column :job_openings, :location, :string
    add_column :job_openings, :type, :string
    add_column :job_openings, :vacancies, :integer
    add_column :job_openings, :salary_min, :integer
    add_column :job_openings, :salary_max, :integer
    add_column :job_openings, :experience, :string
    add_column :job_openings, :skills, :string
    add_column :job_openings, :posted, :date
    add_column :job_openings, :applications, :integer
  end
end
