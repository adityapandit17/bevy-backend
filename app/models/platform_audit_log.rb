# frozen_string_literal: true

class PlatformAuditLog < ApplicationRecord
  ACTION_LABELS = {
    "company.create" => "Company created",
    "company.update" => "Company updated",
    "company.end_trial" => "Trial ended",
    "company.extend_trial" => "Trial extended",
    "company.restart_trial" => "Trial restarted",
    "company.activate" => "Subscription activated",
    "company.feature_flags.update" => "Feature flags updated",
    "admin.create" => "Platform admin created",
    "admin.update" => "Platform admin updated",
    "admin.deactivate" => "Platform admin deactivated",
    "admin.password_reset" => "Admin password reset",
    "settings.update" => "Platform settings updated",
    "pricing_plan.create" => "Pricing plan created",
    "pricing_plan.update" => "Pricing plan updated",
    "pricing_plan.destroy" => "Pricing plan deleted",
    "inquiry.create" => "Inquiry created",
    "inquiry.update" => "Inquiry updated",
    "inquiry.destroy" => "Inquiry deleted",
    "follow_up.create" => "Follow-up created",
    "follow_up.update" => "Follow-up updated",
    "follow_up.destroy" => "Follow-up deleted",
    "campaign.create" => "Campaign created",
    "campaign.update" => "Campaign updated",
    "campaign.destroy" => "Campaign deleted",
    "announcement.create" => "Announcement created",
    "announcement.update" => "Announcement updated",
    "announcement.destroy" => "Announcement deleted",
    "invoice.create" => "Invoice created",
    "invoice.update" => "Invoice updated",
    "invoice.destroy" => "Invoice deleted",
    "subscription_request.approve" => "Subscription request approved",
    "subscription_request.reject" => "Subscription request rejected"
  }.freeze

  belongs_to :platform_admin_user
  belongs_to :company, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_company, ->(company) { where(company_id: company.is_a?(Company) ? company.id : company) }
  scope :global_only, -> { where(company_id: nil) }

  def self.record!(admin:, action:, company: nil, resource: nil, metadata: {}, request: nil)
    create!(
      platform_admin_user: admin,
      company: company,
      action: action,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      metadata: metadata,
      ip_address: request&.remote_ip
    )
  end

  def label
    ACTION_LABELS[action] || action.humanize
  end

  def platform_json
    {
      id: id,
      action: action,
      label: label,
      admin_id: platform_admin_user_id,
      admin_name: platform_admin_user&.name,
      admin_email: platform_admin_user&.email,
      company_id: company_id,
      company_name: company&.name,
      resource_type: resource_type,
      resource_id: resource_id,
      metadata: metadata,
      ip_address: ip_address,
      created_at: created_at
    }
  end
end
