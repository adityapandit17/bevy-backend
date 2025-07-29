class CreateJobOpenings < ActiveRecord::Migration[8.0]
  def change
    create_table :job_openings do |t|
      t.string :title
      t.references :department, null: false, foreign_key: true
      t.text :description
      t.string :requirements
      t.string :status
      t.string :location
      t.string :type
      t.integer :vacancies
      t.integer :salary_min
      t.integer :salary_max
      t.string :experience
      t.string :skills
      t.date :posted
      t.integer :applications
      t.timestamps
    end
  end
end
