require "test_helper"

class ApiAssetsLabelTest < ActionDispatch::IntegrationTest
  def setup
    @asset = assets(:one)
    @user = users(:one)
    @token = JwtService.generate_token(@user)
  end

  def auth_headers
    { Authorization: "Bearer #{@token}" }
  end

  test "lookup finds asset by scan payload" do
    get "/api/assets/lookup", params: { code: @asset.scan_payload }, headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @asset.id, body.dig("asset", "id")
    assert_equal @asset.asset_tag, body.dig("asset", "asset_tag")
  end

  test "lookup finds asset by asset tag" do
    get "/api/assets/lookup", params: { code: @asset.asset_tag }, headers: auth_headers
    assert_response :success
    assert_equal @asset.id, JSON.parse(response.body).dig("asset", "id")
  end

  test "lookup returns 404 for unknown code" do
    get "/api/assets/lookup", params: { code: "BEVYHR|AST|UNKNOWN" }, headers: auth_headers
    assert_response :not_found
  end

  test "qr_code returns png" do
    get "/api/assets/#{@asset.id}/qr_code", headers: auth_headers
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.start_with?("\x89PNG".b)
  end

  test "barcode returns png" do
    get "/api/assets/#{@asset.id}/barcode", headers: auth_headers
    assert_response :success
    assert_equal "image/png", response.media_type
    assert response.body.start_with?("\x89PNG".b)
  end

  test "label returns metadata and data urls" do
    get "/api/assets/#{@asset.id}/label", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @asset.asset_tag, body.dig("label", "asset_tag")
    assert body["qr_code_data_url"].start_with?("data:image/png;base64,")
    assert body["barcode_data_url"].start_with?("data:image/png;base64,")
  end

  test "show includes label urls" do
    get "/api/assets/#{@asset.id}", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @asset.asset_tag, body.dig("asset", "asset_tag")
    assert body.dig("asset", "label", "qr_code_url").include?("/qr_code")
    assert body.dig("asset", "label", "barcode_url").include?("/barcode")
  end
end
