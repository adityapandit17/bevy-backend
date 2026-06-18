# frozen_string_literal: true

class PlatformAdminUser < ApplicationRecord
  ROLES = %w[super_admin support billing].freeze
  STATUSES = %w[active inactive suspended].freeze

  devise :database_authenticatable, :validatable

  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def name
    "#{first_name} #{last_name}"
  end

  def active?
    status == "active"
  end

  def update_last_login!
    update_column(:last_login_at, Time.current)
  end
end
