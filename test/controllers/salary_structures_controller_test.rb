require "test_helper"

class SalaryStructuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @salary_structure = salary_structures(:one)
  end

  test "should get index" do
    get salary_structures_url
    assert_response :success
  end

  test "should get show" do
    get salary_structure_url(@salary_structure)
    assert_response :success
  end

  test "should create salary structure" do
    post salary_structures_url, params: {
      salary_structure: {
        employee_id: @salary_structure.employee_id,
        basic_salary: 50000,
        allowances: 10000,
        deductions: 5000,
        effective_date: Date.current
      }
    }, as: :json
    assert_response :created
  end

  test "should update salary structure" do
    patch salary_structure_url(@salary_structure), params: {
      salary_structure: { basic_salary: 55000 }
    }, as: :json
    assert_response :success
  end

  test "should destroy salary structure" do
    delete salary_structure_url(@salary_structure)
    assert_response :success
  end
end
