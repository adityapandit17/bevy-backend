require "test_helper"

class EmployeeDocumentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get employee_documents_index_url
    assert_response :success
  end

  test "should get show" do
    get employee_documents_show_url
    assert_response :success
  end

  test "should get create" do
    get employee_documents_create_url
    assert_response :success
  end

  test "should get update" do
    get employee_documents_update_url
    assert_response :success
  end

  test "should get destroy" do
    get employee_documents_destroy_url
    assert_response :success
  end
end
