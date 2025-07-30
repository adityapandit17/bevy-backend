class CreatePerformanceReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :performance_reviews do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :period
      t.decimal :rating
      t.string :reviewer
      t.date :review_date
      t.text :comments
      t.text :goals
      t.text :achievements
      t.text :areas_for_improvement

      t.timestamps
    end
  end
end
