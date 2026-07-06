class PerformanceReviewsController < ApplicationController
  before_action :set_performance_review, only: [ :show, :update, :destroy ]

  def index
    @performance_reviews = PerformanceReview.includes(:employee).recent
    @performance_reviews = @performance_reviews.by_employee(params[:employee_id]) if params[:employee_id].present?
    render json: @performance_reviews.map { |r| format_review(r) }
  end

  def stats
    reviews = PerformanceReview.all
    ratings = reviews.where.not(rating: nil).pluck(:rating)
    avg = ratings.any? ? (ratings.sum / ratings.size.to_f).round(1) : 0
    goals_completed = PerformanceGoal.completed.count
    overdue_reviews = reviews.count { |r| r.is_overdue? }

    render json: {
      active_reviews: reviews.this_year.count,
      average_rating: avg,
      goals_completed: goals_completed,
      overdue_reviews: overdue_reviews,
      total_reviews: reviews.count
    }
  end

  def by_employee
    employee_id = params[:employee_id]
    return render json: { error: "employee_id is required" }, status: :bad_request if employee_id.blank?

    reviews = PerformanceReview.includes(:employee).by_employee(employee_id).recent
    render json: reviews.map { |r| format_review(r) }
  end

  def show
    render json: format_review(@performance_review)
  end

  def create
    @performance_review = PerformanceReview.new(performance_review_params)
    if @performance_review.save
      render json: format_review(@performance_review), status: :created
    else
      render json: { errors: @performance_review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @performance_review.update(performance_review_params)
      render json: format_review(@performance_review)
    else
      render json: { errors: @performance_review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @performance_review.destroy
    head :no_content
  end

  private

  def set_performance_review
    @performance_review = PerformanceReview.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Performance review not found" }, status: :not_found
  end

  def performance_review_params
    params.require(:performance_review).permit(:employee_id, :period, :rating, :reviewer, :review_date, :comments, :goals, :achievements, :areas_for_improvement)
  end

  def format_review(review)
    review.as_json.merge(
      "employee_name" => review.employee_name,
      "employee_department" => review.employee_department,
      "rating_description" => review.rating_description,
      "rating_color" => review.rating_color,
      "formatted_review_date" => review.formatted_review_date
    )
  end
end
