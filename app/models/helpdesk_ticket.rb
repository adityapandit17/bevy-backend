class HelpdeskTicket < ApplicationRecord
  belongs_to :assigned_to, class_name: "Employee", foreign_key: :assigned_to_id, optional: true
  belongs_to :requester, class_name: "Employee", foreign_key: :requester_id, optional: true
  has_many :ticket_comments, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :priority, inclusion: { in: %w[low medium high] }
  validates :status, inclusion: { in: %w[open in-progress pending resolved closed] }
  validates :sla_status, inclusion: { in: %w[on-track at-risk breached] }
  validates :channel, inclusion: { in: %w[email phone portal system] }

  # Scopes
  scope :open, -> { where(status: "open") }
  scope :in_progress, -> { where(status: "in-progress") }
  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where(status: "resolved") }
  scope :closed, -> { where(status: "closed") }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_status, ->(status) { where(status: status) }
  scope :high_priority, -> { where(priority: "high") }
  scope :at_risk, -> { where(sla_status: "at-risk") }
  scope :breached, -> { where(sla_status: "breached") }

  # Callbacks
  before_save :update_sla_status

  # Helper methods
  def tags_list
    return [] if tags.blank?
    
    if tags.strip.start_with?('[') && tags.strip.end_with?(']')
      begin
        parsed = JSON.parse(tags)
        return parsed if parsed.is_a?(Array)
      rescue JSON::ParserError
      end
    end
    
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tags_list=(tag_array)
    self.tags = tag_array.is_a?(Array) ? tag_array.join(", ") : tag_array
  end

  def sla_display
    return "#{sla_hours}h" if sla_hours.present?
    "N/A"
  end

  def assigned_to_name
    assigned_to ? "#{assigned_to.first_name} #{assigned_to.last_name}" : "Unassigned"
  end

  def requester_name
    requester ? "#{requester.first_name} #{requester.last_name}" : "Unknown"
  end

  private

  def update_sla_status
    return unless sla_hours.present? && created_at.present?
    
    hours_elapsed = (Time.current - created_at) / 1.hour
    hours_remaining = sla_hours - hours_elapsed
    
    if hours_remaining < 0
      self.sla_status = "breached"
    elsif hours_remaining < (sla_hours * 0.2) # Less than 20% time remaining
      self.sla_status = "at-risk"
    else
      self.sla_status = "on-track"
    end
  end
end
