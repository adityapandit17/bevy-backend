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

  test "ice_config omits turn servers without username and credential" do
    previous = %w[TURN_URLS TURN_USERNAME TURN_CREDENTIAL].to_h { |key| [ key, ENV[key] ] }
    ENV["TURN_URLS"] = "turn:example.com:3478"
    ENV.delete("TURN_USERNAME")
    ENV.delete("TURN_CREDENTIAL")

    get "/api/v1/calls/ice_config", headers: @headers, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    servers = body["data"]["ice_servers"]
    assert servers.none? { |s| s["urls"].to_s.include?("turn:") }
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test "ice_config includes turn servers when credentials are configured" do
    previous = %w[TURN_URLS TURN_USERNAME TURN_CREDENTIAL].to_h { |key| [ key, ENV[key] ] }
    ENV["TURN_URLS"] = "turn:example.com:3478?transport=udp"
    ENV["TURN_USERNAME"] = "bevyhr"
    ENV["TURN_CREDENTIAL"] = "secret"

    get "/api/v1/calls/ice_config", headers: @headers, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    turn = body["data"]["ice_servers"].find { |s| s["urls"].to_s.include?("turn:") }
    assert turn
    assert_equal "bevyhr", turn["username"]
    assert_equal "secret", turn["credential"]
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
