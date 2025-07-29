require "test_helper"

class CandidatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get candidates_index_url
    assert_response :success
  end

  test "should get show" do
    get candidates_show_url
    assert_response :success
  end

  test "should get create" do
    get candidates_create_url
    assert_response :success
  end

  test "should get update" do
    get candidates_update_url
    assert_response :success
  end

  test "should get destroy" do
    get candidates_destroy_url
    assert_response :success
  end
end
