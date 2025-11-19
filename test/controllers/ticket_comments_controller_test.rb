require "test_helper"

class TicketCommentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ticket_comments_index_url
    assert_response :success
  end

  test "should get create" do
    get ticket_comments_create_url
    assert_response :success
  end

  test "should get update" do
    get ticket_comments_update_url
    assert_response :success
  end

  test "should get destroy" do
    get ticket_comments_destroy_url
    assert_response :success
  end
end
