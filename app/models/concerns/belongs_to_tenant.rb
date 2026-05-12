# frozen_string_literal: true

module BelongsToTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :company
    validates :company_id, presence: true, on: :create
    before_validation :assign_company_from_current, on: :create

    scope :for_current_company, -> {
      if Current.company
        where(company_id: Current.company.id)
      else
        none
      end
    }
  end

  private

  def assign_company_from_current
    self.company_id ||= Current.company&.id
  end
end
