class CreateCandidates < ActiveRecord::Migration[8.0]
  def change
    create_table :candidates do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :position
      t.string :department
      t.string :experience
      t.string :location
      t.string :status
      t.date :applied_date
      t.date :last_contact
      t.string :resume
      t.string :cover_letter
      t.text :notes
      t.text :skills
      t.string :education
      t.string :current_company
      t.string :expected_salary
      t.string :availability

      t.timestamps
    end
  end
end
