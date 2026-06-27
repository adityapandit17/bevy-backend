# frozen_string_literal: true

class PlatformSetting < ApplicationRecord
  DEFAULTS = {
    "product_name" => "BevyHR",
    "marketing_url" => "http://localhost:3001/home",
    "tenant_app_url" => "http://localhost:3001",
    "maintenance_mode" => "false",
    "allow_signups" => "true",
    "require_email_verification" => "false",
    "default_trial_days" => "14"
  }.freeze

  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value || DEFAULTS[key.to_s]
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.value = value.to_s
    record.save!
  end

  def self.all_settings
    DEFAULTS.merge(pluck(:key, :value).to_h)
  end

  def self.settings_json
    raw = all_settings
    {
      product_name: raw["product_name"],
      marketing_url: raw["marketing_url"],
      tenant_app_url: raw["tenant_app_url"],
      maintenance_mode: raw["maintenance_mode"] == "true",
      allow_signups: raw["allow_signups"] == "true",
      require_email_verification: raw["require_email_verification"] == "true",
      default_trial_days: raw["default_trial_days"].to_i
    }
  end

  def self.update_settings!(params)
    params.each do |key, value|
      set(key, value)
    end
  end
end
