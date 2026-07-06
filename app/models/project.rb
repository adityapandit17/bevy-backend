# frozen_string_literal: true

class Project < ApplicationRecord
  include TenantScoped

  has_many :project_tasks, dependent: :destroy

  STATUSES = %w[planning active completed on_hold cancelled].freeze
  PRIORITIES = %w[low medium high critical].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :recent, -> { order(updated_at: :desc) }

  def tasks_completed_count
    project_tasks.where(status: %w[completed done]).count
  end

  def tasks_total_count
    project_tasks.count
  end
end
