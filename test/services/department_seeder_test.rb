# frozen_string_literal: true

require "test_helper"

class DepartmentSeederTest < ActiveSupport::TestCase
  test "seeds all default department names" do
    company = Company.create!(
      name: "Seeder Test Co",
      code: "SEED#{SecureRandom.hex(2).upcase}",
      industry: "technology",
      employee_count: "1-50",
      timezone: "asia-kolkata",
      currency: "inr",
      country_code: "IN",
      status: "trial",
      plan: "starter"
    )

    ActsAsTenant.with_tenant(company) do
      assert_difference("Department.count", DepartmentSeeder.default_names.size) do
        DepartmentSeeder.seed!
      end

      DepartmentSeeder.default_names.each do |name|
        assert Department.exists?(name: name), "expected department #{name}"
      end
    end
  end

  test "seed is idempotent" do
    company = Company.create!(
      name: "Seeder Idempotent Co",
      code: "SEED#{SecureRandom.hex(2).upcase}",
      industry: "technology",
      employee_count: "1-50",
      timezone: "asia-kolkata",
      currency: "inr",
      country_code: "IN",
      status: "trial",
      plan: "starter"
    )

    ActsAsTenant.with_tenant(company) do
      DepartmentSeeder.seed!

      assert_no_difference("Department.count") do
        DepartmentSeeder.seed!
      end
    end
  end
end
