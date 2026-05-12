class TicketComment < ApplicationRecord
  include BelongsToTenant

  belongs_to :helpdesk_ticket
  belongs_to :user, optional: true
  belongs_to :employee, optional: true

  # Validations
  validates :content, presence: true
  validates :helpdesk_ticket_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  # Helper methods
  def author_name
    if employee.present?
      "#{employee.first_name} #{employee.last_name}".strip
    elsif user.present?
      user.name.presence || user.email
    else
      "Unknown"
    end
  end

  def author_email
    if employee.present?
      employee.email
    elsif user.present?
      user.email
    else
      nil
    end
  end
end
