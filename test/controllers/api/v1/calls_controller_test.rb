require "test_helper"

class Api::V1::CallsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @headers = jwt_headers_for(@user)
  end

  test "ice_config requires authentication" do
    get "/api/v1/calls/ice_config"
    assert_response :unauthorized
  end

  test "ice_config returns default stun servers" do
    get "/api/v1/calls/ice_config", headers: @headers, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"]
    assert body["data"]["ice_servers"].is_a?(Array)
    assert body["data"]["ice_servers"].any? { |s| s["urls"].to_s.include?("stun:") }
  end
end
