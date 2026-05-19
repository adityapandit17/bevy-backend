class AddWorkSettingsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :weekly_working_hours, :decimal, precision: 5, scale: 2, default: 40.0
    add_column :companies, :work_start_time, :string, default: "09:00"
    add_column :companies, :work_end_time, :string, default: "18:00"
    add_column :companies, :lunch_duration_minutes, :integer, default: 60
  end
end
