class PerformanceReviewsController < ApplicationController
  before_action :set_performance_review, only: [ :show, :update, :destroy ]

  def index
    @performance_reviews = PerformanceReview.all
    render json: @performance_reviews
  end

  def show
    render json: @performance_review
  end

  def create
    @performance_review = PerformanceReview.new(performance_review_params)
    if @performance_review.save
      render json: @performance_review, status: :created
    else
      render json: { errors: @performance_review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @performance_review.update(performance_review_params)
      render json: @performance_review
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
end
