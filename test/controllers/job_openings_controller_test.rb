require "test_helper"

class JobOpeningsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get job_openings_index_url
    assert_response :success
  end

  test "should get show" do
    get job_openings_show_url
    assert_response :success
  end

  test "should get create" do
    get job_openings_create_url
    assert_response :success
  end

  test "should get update" do
    get job_openings_update_url
    assert_response :success
  end

  test "should get destroy" do
    get job_openings_destroy_url
    assert_response :success
  end
end
