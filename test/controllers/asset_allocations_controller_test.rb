require "test_helper"

class AssetAllocationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get asset_allocations_index_url
    assert_response :success
  end

  test "should get show" do
    get asset_allocations_show_url
    assert_response :success
  end

  test "should get create" do
    get asset_allocations_create_url
    assert_response :success
  end

  test "should get update" do
    get asset_allocations_update_url
    assert_response :success
  end

  test "should get destroy" do
    get asset_allocations_destroy_url
    assert_response :success
  end

  test "should get return" do
    get asset_allocations_return_url
    assert_response :success
  end
end
