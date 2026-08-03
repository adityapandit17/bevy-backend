# frozen_string_literal: true

class CompanyFeatureFlag < ApplicationRecord
  DEFAULT_FLAGS = %w[chat mobile_app ai_assistant impersonation].freeze

  belongs_to :company

  validates :key, presence: true, uniqueness: { scope: :company_id }

  def self.for_company(company)
    flags = where(company: company).index_by(&:key)
    DEFAULT_FLAGS.index_with do |key|
      flags[key]&.enabled || false
    end
  end

  def self.update_for_company!(company, flags_hash)
    flags_hash.each do |key, enabled|
      record = find_or_initialize_by(company: company, key: key.to_s)
      record.enabled = ActiveModel::Type::Boolean.new.cast(enabled)
      record.save!
    end

    # Bust /auth/me company_settings cache (keyed on company.updated_at)
    company.touch
  end
end
