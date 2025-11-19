class SlaWorkflow < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :priority, inclusion: { in: %w[low medium high] }
  validates :status, inclusion: { in: %w[active inactive] }
  validates :sla_hours, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_priority, ->(priority) { where(priority: priority) }

  # Helper methods
  def escalation_levels_list
    return [] if escalation_levels.blank?
    
    if escalation_levels.strip.start_with?('[') && escalation_levels.strip.end_with?(']')
      begin
        parsed = JSON.parse(escalation_levels)
        return parsed if parsed.is_a?(Array)
      rescue JSON::ParserError
      end
    end
    
    []
  end

  def escalation_levels_list=(levels_array)
    self.escalation_levels = levels_array.is_a?(Array) ? JSON.generate(levels_array) : levels_array
  end

  def sla_display
    "#{sla_hours}h"
  end

  def avg_resolution_display
    return "N/A" unless avg_resolution_hours.present?
    "#{avg_resolution_hours.to_i}h"
  end
end
