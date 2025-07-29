class CreateInterviews < ActiveRecord::Migration[8.0]
  def change
    create_table :interviews do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string :interview_type
      t.date :scheduled_date
      t.time :scheduled_time
      t.string :interviewer
      t.string :status
      t.text :notes
      t.text :feedback
      t.integer :rating

      t.timestamps
    end
  end
end
