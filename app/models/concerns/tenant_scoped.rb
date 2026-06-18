# frozen_string_literal: true

module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :company
    belongs_to :company

    before_validation :assign_company_from_tenant
  end

  private

  def assign_company_from_tenant
    self.company ||= ActsAsTenant.current_tenant
  end
end
