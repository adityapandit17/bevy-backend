# frozen_string_literal: true

class ProjectTask < ApplicationRecord
  include TenantScoped

  belongs_to :project
  belongs_to :employee, optional: true

  STATUSES = %w[backlog todo in_progress review completed done pending].freeze
  PRIORITIES = %w[low medium high critical].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :by_project, ->(project_id) { where(project_id: project_id) if project_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_sprint, ->(sprint) { where(sprint_name: sprint) if sprint.present? }

  def assignee_display_name
    employee&.name || assignee_name || "Unassigned"
  end
end
