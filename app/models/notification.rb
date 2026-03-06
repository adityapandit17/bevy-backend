class Notification < ApplicationRecord
  belongs_to :user

  # Use new enum syntax compatible with Rails 7.1+/8.x and Ruby keyword args
  enum :notification_type, {
    leave: "leave",
    attendance: "attendance",
    payroll: "payroll",
    system: "system",
    announcement: "announcement",
    reminder: "reminder"
  }

  scope :unread, -> { where(read: false) }

  validates :title, :message, :notification_type, presence: true
end
