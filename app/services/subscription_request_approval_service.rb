# frozen_string_literal: true

class SubscriptionRequestApprovalService
  class ApprovalError < StandardError; end

  def initialize(request, approver: nil)
    @request = request
    @approver = approver
  end

  def approve!
    raise ApprovalError, "Request is not pending" unless request.status == "pending"

    ActiveRecord::Base.transaction do
      company = resolve_company!
      apply_subscription!(company)
      request.update!(status: "approved")
      company
    end
  end

  def reject!(notes: nil)
    raise ApprovalError, "Request is not pending" unless request.status == "pending"

    request.update!(status: "rejected", notes: [ request.notes, notes ].compact.join("\n"))
  end

  private

  attr_reader :request, :approver

  def resolve_company!
    return request.company if request.company.present?

    raise ApprovalError, "Company is required for this request" if request.company_name.blank?

    Company.find_by(name: request.company_name) ||
      Company.find_by(code: request.company_name) ||
      raise(ApprovalError, "Company not found for request")
  end

  def apply_subscription!(company)
    case request.request_type
    when "new_tenant"
      company.activate_subscription!(plan: request.plan, billing_cycle: request.billing_cycle)
    when "upgrade", "renewal"
      company.activate_subscription!(plan: request.plan, billing_cycle: request.billing_cycle)
    when "seat_add"
      company.update!(max_employees: company.max_employees.to_i + request.seats.to_i)
    end

    company.update!(plan: request.plan) if request.plan.present?
  end
end
