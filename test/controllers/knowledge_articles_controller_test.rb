require "test_helper"

class KnowledgeArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get knowledge_articles_index_url
    assert_response :success
  end

  test "should get show" do
    get knowledge_articles_show_url
    assert_response :success
  end

  test "should get create" do
    get knowledge_articles_create_url
    assert_response :success
  end

  test "should get update" do
    get knowledge_articles_update_url
    assert_response :success
  end

  test "should get destroy" do
    get knowledge_articles_destroy_url
    assert_response :success
  end
end
