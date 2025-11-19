require "test_helper"

class SlaWorkflowsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sla_workflows_index_url
    assert_response :success
  end

  test "should get show" do
    get sla_workflows_show_url
    assert_response :success
  end

  test "should get create" do
    get sla_workflows_create_url
    assert_response :success
  end

  test "should get update" do
    get sla_workflows_update_url
    assert_response :success
  end

  test "should get destroy" do
    get sla_workflows_destroy_url
    assert_response :success
  end
end
