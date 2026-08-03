# frozen_string_literal: true

require "test_helper"

class SalaryStructureTest < ActiveSupport::TestCase
  setup do
    @company = companies(:one)
    ActsAsTenant.current_tenant = @company
    @employee = employees(:one)
    @employee.salary_structures.destroy_all
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "current_for returns the structure active on a date" do
    first = SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 500_000,
      hra: 100_000,
      allowances: 50_000,
      annual_ctc: 650_000,
      effective_from: Date.new(2024, 1, 1),
      revision_type: "joining"
    )
    second = SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 600_000,
      hra: 120_000,
      allowances: 60_000,
      annual_ctc: 780_000,
      effective_from: Date.new(2025, 4, 1),
      revision_type: "appraisal",
      notes: "Annual hike"
    )

    first.reload
    assert_equal Date.new(2025, 3, 31), first.effective_upto
    assert_equal first.id, SalaryStructure.current_for(@employee, on: Date.new(2025, 3, 15)).id
    assert_equal second.id, SalaryStructure.current_for(@employee, on: Date.new(2025, 4, 1)).id
    assert_equal second.id, @employee.current_salary_structure.id
  end

  test "appraisal_history_for returns newest first with change percent" do
    SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 500_000,
      annual_ctc: 600_000,
      effective_from: Date.new(2024, 1, 1),
      revision_type: "joining"
    )
    SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 550_000,
      annual_ctc: 720_000,
      effective_from: Date.new(2025, 1, 1),
      revision_type: "appraisal",
      notes: "FY25 appraisal"
    )

    history = SalaryStructure.appraisal_history_for(@employee)
    assert_equal 2, history.size
    assert_equal "appraisal", history.first[:revision_type]
    assert_equal 720_000.0, history.first[:annual_ctc]
    assert_equal 120_000.0, history.first[:change_amount]
    assert_in_delta 20.0, history.first[:change_percent], 0.01
    assert_equal "joining", history.second[:revision_type]
    assert_nil history.second[:change_amount]
  end

  test "employee salary uses current structure basic" do
    SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 400_000,
      annual_ctc: 400_000,
      effective_from: Date.new(2023, 1, 1),
      revision_type: "joining"
    )
    SalaryStructure.create!(
      employee: @employee,
      department_id: @employee.department_id,
      basic: 480_000,
      annual_ctc: 480_000,
      effective_from: Date.new(2024, 6, 1),
      revision_type: "appraisal"
    )

    assert_equal 480_000, @employee.salary
  end
end
