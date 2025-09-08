require "test_helper"

class PerformanceReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @performance_review = performance_reviews(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      period: "Q1 2025",
      rating: 4,
      reviewer: "John Manager",
      review_date: Date.current,
      comments: "Excellent performance throughout the year",
      goals: "Complete project A, Improve team collaboration",
      achievements: "All goals met and exceeded expectations",
      areas_for_improvement: "Continue developing leadership skills"
    }
  end

  test "should get index" do
    get performance_reviews_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show performance review" do
    get performance_review_url(@performance_review), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @performance_review.id, json_response["id"]
  end

  test "should create performance review" do
    assert_difference('PerformanceReview.count') do
      post performance_reviews_url, params: { performance_review: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:employee_id], json_response["employee_id"]
    assert_equal "4.0", json_response["rating"]
  end

  test "should not create performance review with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('PerformanceReview.count') do
      post performance_reviews_url, params: { performance_review: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update performance review" do
    patch performance_review_url(@performance_review), params: { 
      performance_review: { rating: 5, comments: "Updated comments" } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "5.0", json_response["rating"]
    assert_equal "Updated comments", json_response["comments"]
  end

  test "should not update performance review with invalid attributes" do
    patch performance_review_url(@performance_review), params: { 
      performance_review: { rating: 6 } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Rating must be less than or equal to 5"
  end

  test "should destroy performance review" do
    assert_difference('PerformanceReview.count', -1) do
      delete performance_review_url(@performance_review), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent performance review" do
    get performance_review_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent performance review" do
    patch performance_review_url(99999), params: { 
      performance_review: { rating: 5 } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent performance review" do
    delete performance_review_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle performance review with all required fields" do
    get performance_review_url(@performance_review), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id period rating reviewer review_date comments created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle performance review with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      period: "Q1 2025",
      rating: 4,
      reviewer: "John Manager",
      review_date: Date.current,
      comments: "Good performance"
    }
    
    post performance_reviews_url, params: { performance_review: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:employee_id], json_response["employee_id"]
    assert_equal "4.0", json_response["rating"]
    # Optional fields should be null
    assert_nil json_response["goals"]
    assert_nil json_response["achievements"]
    assert_nil json_response["areas_for_improvement"]
  end
end
