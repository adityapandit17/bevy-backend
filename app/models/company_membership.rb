# frozen_string_literal: true

class CompanyMembership < ApplicationRecord
  belongs_to :company
  belongs_to :user

  validates :status, presence: true, inclusion: { in: %w[active invited] }
  validates :user_id, uniqueness: { scope: :company_id }
  validates :role, length: { maximum: 100 }, allow_blank: true

  scope :active, -> { where(status: "active") }
end
