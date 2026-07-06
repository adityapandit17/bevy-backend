# frozen_string_literal: true

class DigitalSignatureAssignmentService
  def self.assign_for_policy!(policy_document, employee_ids: nil)
    return [] unless policy_document.requires_signature?

    employees = if employee_ids.present?
      Employee.where(id: employee_ids, status: "active")
    else
      Employee.where(status: "active")
    end

    created = []
    employees.find_each do |employee|
      signature = DigitalSignature.find_or_initialize_by(
        policy_document: policy_document,
        employee: employee
      )
      next if signature.persisted?

      signature.status = "pending"
      signature.signature_type = "pending"
      if signature.save
        created << signature
      end
    end
    created
  end
end
