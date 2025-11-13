class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :language, default: "en"
      t.string :timezone, default: "UTC"
      t.string :date_format, default: "MM/DD/YYYY"
      t.string :theme, default: "light"
      t.boolean :email_notifications, default: true
      t.boolean :push_notifications, default: true
      t.boolean :leave_notifications, default: true
      t.boolean :attendance_notifications, default: true
      t.boolean :payroll_notifications, default: false
      t.boolean :system_notifications, default: true

      t.timestamps
    end
  end
end
