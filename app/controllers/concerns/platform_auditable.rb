# frozen_string_literal: true

module PlatformAuditable
  extend ActiveSupport::Concern

  private

  def audit_action!(action:, company: nil, resource: nil, metadata: {})
    return unless current_platform_admin

    PlatformAuditLog.record!(
      admin: current_platform_admin,
      action: action,
      company: company,
      resource: resource,
      metadata: metadata,
      request: request
    )
  end

  def audit_record_update!(action:, record:, company: nil, metadata: {})
    changes = record.previous_changes.except("updated_at", "created_at")
    return if changes.blank?

    resolved_company = company || (record.is_a?(Company) ? record : nil)
    audit_action!(
      action: action,
      company: resolved_company,
      resource: record,
      metadata: metadata.merge(changes: changes)
    )
  end
end
