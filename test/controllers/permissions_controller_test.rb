require "test_helper"

class PermissionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get permissions_index_url
    assert_response :success
  end

  test "should get show" do
    get permissions_show_url
    assert_response :success
  end
end
