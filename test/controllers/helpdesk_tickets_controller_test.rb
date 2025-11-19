require "test_helper"

class HelpdeskTicketsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get helpdesk_tickets_index_url
    assert_response :success
  end

  test "should get show" do
    get helpdesk_tickets_show_url
    assert_response :success
  end

  test "should get create" do
    get helpdesk_tickets_create_url
    assert_response :success
  end

  test "should get update" do
    get helpdesk_tickets_update_url
    assert_response :success
  end

  test "should get destroy" do
    get helpdesk_tickets_destroy_url
    assert_response :success
  end

  test "should get stats" do
    get helpdesk_tickets_stats_url
    assert_response :success
  end
end
