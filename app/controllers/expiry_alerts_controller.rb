# frozen_string_literal: true

class ExpiryAlertsController < ApplicationController
  def index
    days = (params[:days] || 30).to_i
    window_end = Date.current + days.days

    employee_docs = EmployeeDocument.includes(:employee)
                                    .where("expiry_date BETWEEN ? AND ?", Date.current, window_end)

    policy_docs = PolicyDocument.where("expiry_date BETWEEN ? AND ?", Date.current, window_end)

    alerts = []

    employee_docs.find_each do |doc|
      alerts << {
        id: "emp-doc-#{doc.id}",
        documentTitle: doc.name,
        documentType: "Employee Document",
        expiryDate: doc.expiry_date.iso8601,
        daysUntilExpiry: (doc.expiry_date - Date.current).to_i,
        priority: priority_for_days((doc.expiry_date - Date.current).to_i),
        assignedTo: doc.uploaded_by || "HR Team",
        status: doc.status,
        employeeName: doc.employee&.name
      }
    end

    policy_docs.find_each do |doc|
      alerts << {
        id: "policy-#{doc.id}",
        documentTitle: doc.title,
        documentType: "Policy Document",
        expiryDate: doc.expiry_date&.iso8601,
        daysUntilExpiry: doc.expiry_date ? (doc.expiry_date - Date.current).to_i : nil,
        priority: doc.expiry_date ? priority_for_days((doc.expiry_date - Date.current).to_i) : "low",
        assignedTo: "HR Manager",
        status: doc.status
      }
    end

    alerts.sort_by! { |a| a[:daysUntilExpiry] || 9999 }

    render json: alerts
  end

  private

  def priority_for_days(days)
    return "high" if days <= 14
    return "medium" if days <= 45

    "low"
  end
end
