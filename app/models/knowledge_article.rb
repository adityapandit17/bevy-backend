class KnowledgeArticle < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft published archived] }

  # Scopes
  scope :published, -> { where(status: "published") }
  scope :draft, -> { where(status: "draft") }
  scope :archived, -> { where(status: "archived") }
  scope :by_category, ->(category) { where(category: category) }

  # Callbacks
  before_save :update_last_updated

  # Helper methods
  def tags_list
    return [] if tags.blank?

    if tags.strip.start_with?("[") && tags.strip.end_with?("]")
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

  def increment_views!
    increment!(:views)
  end

  def increment_helpful!
    increment!(:helpful)
  end

  def last_updated_display
    return updated_at.strftime("%B %d, %Y") if last_updated.blank?
    last_updated.strftime("%B %d, %Y")
  end

  private

  def update_last_updated
    self.last_updated = Time.current if status_changed? || content_changed?
  end
end
