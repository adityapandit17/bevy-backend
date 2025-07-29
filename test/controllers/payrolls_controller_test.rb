require "test_helper"

class PayrollsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get payrolls_index_url
    assert_response :success
  end

  test "should get show" do
    get payrolls_show_url
    assert_response :success
  end

  test "should get create" do
    get payrolls_create_url
    assert_response :success
  end

  test "should get update" do
    get payrolls_update_url
    assert_response :success
  end

  test "should get destroy" do
    get payrolls_destroy_url
    assert_response :success
  end
end
