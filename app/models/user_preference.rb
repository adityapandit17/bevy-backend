class UserPreference < ApplicationRecord
  belongs_to :user

  validates :language, inclusion: { in: %w[en es fr de] }, allow_nil: true
  validates :timezone, presence: true
  validates :date_format, inclusion: { in: ["MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD", "DD MMM YYYY"] }, allow_nil: true
  validates :theme, inclusion: { in: %w[light dark system] }, allow_nil: true

  # Ensure one preference per user
  validates :user_id, uniqueness: true

  def self.for_user(user)
    find_or_create_by(user: user) do |pref|
      pref.language = "en"
      pref.timezone = "UTC"
      pref.date_format = "MM/DD/YYYY"
      pref.theme = "light"
      pref.email_notifications = true
      pref.push_notifications = true
      pref.leave_notifications = true
      pref.attendance_notifications = true
      pref.payroll_notifications = false
      pref.system_notifications = true
    end
  end
end

