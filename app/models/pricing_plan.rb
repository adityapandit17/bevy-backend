# frozen_string_literal: true

class PricingPlan < ApplicationRecord
  validates :slug, :name, presence: true
  validates :slug, uniqueness: true
  validates :monthly_price, :annual_price, :max_employees, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :monthly_price) }

  def self.monthly_rate_for(plan_slug)
    find_by(slug: plan_slug.to_s)&.monthly_price || default_rates[plan_slug.to_s] || 2999
  end

  def self.default_rates
    { "starter" => 2999, "professional" => 7999, "enterprise" => 19_999 }
  end

  def platform_json
    {
      id: id,
      slug: slug,
      name: name,
      description: description,
      monthly_price: monthly_price,
      annual_price: annual_price,
      per_seat_price: per_seat_price,
      max_employees: max_employees,
      features: features || [],
      published: published,
      popular: popular,
      position: position
    }
  end
end
