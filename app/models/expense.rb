# frozen_string_literal: true

class Expense < ApplicationRecord
  include TenantScoped

  belongs_to :employee

  STATUSES = %w[submitted approved rejected reimbursed].freeze

  validates :title, :category, :expense_date, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(expense_date: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? && category != "all" }

  def employee_name
    employee.name
  end
end
