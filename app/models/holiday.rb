# frozen_string_literal: true

class Holiday < ApplicationRecord
  include TenantScoped

  belongs_to :created_by, class_name: "User", optional: true

  validates :date, presence: true
  validates :name, presence: true, length: { maximum: 120 }
  validates :date, uniqueness: { scope: :company_id, message: "already has a holiday configured" }

  scope :for_year, ->(year) { where(date: Date.new(year.to_i, 1, 1)..Date.new(year.to_i, 12, 31)) }
  scope :in_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :ordered, -> { order(:date) }
end
