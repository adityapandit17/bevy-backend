require "test_helper"

class RolesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get roles_url
    assert_response :success
  end


  test "should get show" do
    get role_url(id: 1)
    assert_response :success
  end


  test "should create role" do
    post roles_url, params: { role: { name: "Test" } }
    assert_response :redirect
  end


  test "should update role" do
    patch role_url(id: 1), params: { role: { name: "Updated" } }
    assert_response :redirect
  end

  test "should destroy role" do
    delete role_url(id: 1)
    assert_response :redirect
  end
end
