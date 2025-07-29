require "test_helper"

class SalaryStructuresControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get salary_structures_index_url
    assert_response :success
  end

  test "should get show" do
    get salary_structures_show_url
    assert_response :success
  end

  test "should get create" do
    get salary_structures_create_url
    assert_response :success
  end

  test "should get update" do
    get salary_structures_update_url
    assert_response :success
  end

  test "should get destroy" do
    get salary_structures_destroy_url
    assert_response :success
  end
end
