class AddFieldsToJobOpenings < ActiveRecord::Migration[8.0]
  def change
    # These columns already exist in create_job_openings migration:
    # :requirements, :location, :type, :vacancies, :salary_min, :salary_max, 
    # :experience, :skills, :posted, :applications
    # 
    # No new columns to add - all were already defined in the initial migration
  end
end
