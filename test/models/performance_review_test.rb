require "test_helper"

class PerformanceReviewTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @review = PerformanceReview.new(
      employee: @employee,
      period: "Q2 2024",
      rating: 4.0,
      reviewer: "Jane Manager",
      review_date: Date.current,
      comments: "Strong performance across all areas."
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @review.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require period" do
    @review.period = nil
    assert_not @review.valid?
    assert_includes @review.errors[:period], "can't be blank"
  end

  test "should require rating" do
    @review.rating = nil
    assert_not @review.valid?
    assert_includes @review.errors[:rating], "can't be blank"
  end

  test "should require reviewer" do
    @review.reviewer = nil
    assert_not @review.valid?
    assert_includes @review.errors[:reviewer], "can't be blank"
  end

  test "should require review_date" do
    @review.review_date = nil
    assert_not @review.valid?
    assert_includes @review.errors[:review_date], "can't be blank"
  end

  test "should require comments" do
    @review.comments = nil
    assert_not @review.valid?
    assert_includes @review.errors[:comments], "can't be blank"
  end

  # ── Numericality validations ──────────────────────────────────────────────
  test "should reject rating below 1" do
    @review.rating = 0
    assert_not @review.valid?
  end

  test "should reject rating above 5" do
    @review.rating = 5.1
    assert_not @review.valid?
  end

  test "should accept boundary rating of 5" do
    @review.rating = 5.0
    assert @review.valid?
  end

  test "should accept boundary rating of 0.1" do
    @review.rating = 0.1
    assert @review.valid?
  end

  # ── Associations ──────────────────────────────────────────────────────────
  test "should belong to employee" do
    assert_respond_to @review, :employee
  end

  test "should require employee" do
    @review.employee = nil
    assert_not @review.valid?
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "by_employee scope filters by employee" do
    @review.save!
    other_review = PerformanceReview.create!(
      employee: employees(:two),
      period: "Q2 2024",
      rating: 3.5,
      reviewer: "Other Manager",
      review_date: Date.current,
      comments: "Good work"
    )
    assert_includes PerformanceReview.by_employee(@employee.id), @review
    assert_not_includes PerformanceReview.by_employee(@employee.id), other_review
  end

  test "this_year scope returns reviews from current year" do
    @review.review_date = Date.current
    @review.save!
    old = PerformanceReview.create!(
      employee: employees(:two),
      period: "Q1 2020",
      rating: 3.0,
      reviewer: "Old Manager",
      review_date: Date.new(2020, 1, 1),
      comments: "Past review"
    )
    assert_includes PerformanceReview.this_year, @review
    assert_not_includes PerformanceReview.this_year, old
  end

  test "recent scope orders by review_date descending" do
    @review.save!
    first_review = @review
    second_review = PerformanceReview.create!(
      employee: employees(:two),
      period: "Q3 2024",
      rating: 4.5,
      reviewer: "New Manager",
      review_date: Date.current + 1.day,
      comments: "Excellent"
    )
    assert_equal second_review, PerformanceReview.recent.first
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "employee_name delegates to employee" do
    assert_equal @employee.name, @review.employee_name
  end

  test "formatted_review_date formats date correctly" do
    @review.review_date = Date.new(2024, 6, 15)
    assert_equal "June 15, 2024", @review.formatted_review_date
  end

  test "rating_description returns Outstanding for 4.5-5.0" do
    @review.rating = 4.8
    assert_equal "Outstanding", @review.rating_description
  end

  test "rating_description returns Excellent for 4.0-4.4" do
    @review.rating = 4.2
    assert_equal "Excellent", @review.rating_description
  end

  test "rating_description returns Good for 3.5-3.9" do
    @review.rating = 3.7
    assert_equal "Good", @review.rating_description
  end

  test "rating_description returns Satisfactory for 3.0-3.4" do
    @review.rating = 3.2
    assert_equal "Satisfactory", @review.rating_description
  end

  test "rating_description returns Needs Improvement for 2.5-2.9" do
    @review.rating = 2.7
    assert_equal "Needs Improvement", @review.rating_description
  end

  test "rating_color returns green for outstanding ratings" do
    @review.rating = 5.0
    assert_equal "green", @review.rating_color
  end

  test "rating_color returns red for low ratings" do
    @review.rating = 1.5
    assert_equal "red", @review.rating_color
  end

  test "achievements_list parses comma-separated achievements" do
    @review.achievements = "Led project, Improved metrics, Mentored juniors"
    @review.save!
    list = @review.achievements_list
    assert_includes list, "Led project"
    assert_includes list, "Improved metrics"
    assert_equal 3, list.length
  end

  test "areas_for_improvement_list parses comma-separated items" do
    @review.areas_for_improvement = "Time management, Documentation"
    @review.save!
    list = @review.areas_for_improvement_list
    assert_equal 2, list.length
    assert_includes list, "Time management"
  end

  test "is_recent? returns true for review within last 6 months" do
    @review.review_date = 2.months.ago.to_date
    assert @review.is_recent?
  end

  test "is_recent? returns false for review older than 6 months" do
    @review.review_date = 8.months.ago.to_date
    assert_not @review.is_recent?
  end

  # ── Callback ──────────────────────────────────────────────────────────────
  test "sets review_date to today if nil before save" do
    @review.review_date = nil
    @review.save!
    assert_equal Date.current, @review.reload.review_date
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create performance review" do
    assert_difference("PerformanceReview.count") { @review.save! }
  end

  test "should update performance review" do
    @review.save!
    @review.update!(rating: 4.5)
    assert_equal 4.5, @review.reload.rating.to_f
  end

  test "should destroy performance review" do
    @review.save!
    assert_difference("PerformanceReview.count", -1) { @review.destroy }
  end
end
