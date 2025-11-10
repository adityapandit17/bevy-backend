class LeavePolicy < ApplicationRecord
  # Validations
  validates :year, presence: true, uniqueness: true, numericality: { only_integer: true }
  validates :holidays_per_year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :annual_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sick_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :personal_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :maternity_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :paternity_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unpaid_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :other_leave, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_year, ->(year) { where(year: year) }
  scope :current, -> { active.by_year(Date.current.year) }

  # Class methods
  def self.current_policy
    current.first || create_default_policy
  end

  def self.for_year(year)
    by_year(year).active.first || create_default_policy_for_year(year)
  end

  def self.create_default_policy
    create_default_policy_for_year(Date.current.year)
  end

  def self.create_default_policy_for_year(year)
    create!(
      year: year,
      holidays_per_year: 10,
      annual_leave: 21,
      sick_leave: 12,
      personal_leave: 5,
      maternity_leave: 90,
      paternity_leave: 15,
      unpaid_leave: 30,
      other_leave: 5,
      active: true
    )
  end

  # Instance methods
  def leave_limit_for_type(leave_type)
    case leave_type.to_s
    when "annual"
      annual_leave
    when "sick"
      sick_leave
    when "personal"
      personal_leave
    when "maternity"
      maternity_leave
    when "paternity"
      paternity_leave
    when "unpaid"
      unpaid_leave
    when "other"
      other_leave
    else
      0
    end
  end

  def to_hash
    {
      year: year,
      holidays_per_year: holidays_per_year,
      annual_leave: annual_leave,
      sick_leave: sick_leave,
      personal_leave: personal_leave,
      maternity_leave: maternity_leave,
      paternity_leave: paternity_leave,
      unpaid_leave: unpaid_leave,
      other_leave: other_leave,
      active: active
    }
  end
end
