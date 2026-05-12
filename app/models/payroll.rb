class Payroll < ApplicationRecord
  include BelongsToTenant

  belongs_to :employee
end
