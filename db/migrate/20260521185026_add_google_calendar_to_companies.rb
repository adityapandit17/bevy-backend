class AddGoogleCalendarToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :google_calendar_email, :string
    add_column :companies, :google_calendar_refresh_token, :text
    add_column :companies, :google_calendar_access_token, :text
    add_column :companies, :google_calendar_token_expires_at, :datetime
    add_column :companies, :google_calendar_connected_at, :datetime
    add_column :companies, :google_calendar_connected_by_user_id, :bigint
  end
end
