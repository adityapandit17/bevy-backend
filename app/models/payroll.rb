class Payroll < ApplicationRecord
  include TenantScoped
  belongs_to :employee
end
