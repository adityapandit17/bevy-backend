class OnboardingTask < ApplicationRecord
  belongs_to :onboarding_employee

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: %w[HR IT Department Training Compliance Performance] }
  validates :priority, presence: true, inclusion: { in: %w[low medium high] }
  validates :due_date, presence: true
  validates :assigned_to, presence: true

  scope :completed, -> { where(is_completed: true) }
  scope :pending, -> { where(is_completed: false) }
  scope :high_priority, -> { where(priority: "high") }
  scope :overdue, -> { where("due_date < ? AND is_completed = ?", Date.current, false) }
  scope :by_status, ->(status) { where(is_completed: status == "completed") }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_priority, ->(priority) { where(priority: priority) }

  def overdue?
    due_date < Date.current && !is_completed
  end

  def due_soon?
    due_date <= Date.current + 3.days && !is_completed
  end

  def documents_list
    return [] if documents.blank?

    # Handle string representation of array (e.g., '["doc1", "doc2"]')
    if documents.strip.start_with?('[') && documents.strip.end_with?(']')
      begin
        parsed = JSON.parse(documents)
        return parsed if parsed.is_a?(Array)
      rescue JSON::ParserError
        # Fall through to comma-split if JSON parsing fails
      end
    end

    # Handle comma-separated string
    documents.split(",").map(&:strip).reject(&:blank?)
  end

  def documents_list=(docs)
    self.documents = docs.is_a?(Array) ? docs.join(", ") : docs
  end
end
