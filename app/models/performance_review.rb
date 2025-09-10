class PerformanceReview < ApplicationRecord
  belongs_to :employee

  # Validations
  validates :period, presence: true
  validates :rating, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :reviewer, presence: true
  validates :review_date, presence: true
  validates :comments, presence: true

  # Scopes
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_period, ->(period) { where(period: period) }
  scope :by_reviewer, ->(reviewer) { where(reviewer: reviewer) }
  scope :recent, -> { order(review_date: :desc) }
  scope :this_year, -> { where("review_date >= ?", Date.current.beginning_of_year) }
  scope :last_year, -> { where("review_date >= ? AND review_date < ?", 1.year.ago.beginning_of_year, Date.current.beginning_of_year) }

  # Callbacks
  before_save :set_default_review_date

  # Helper methods
  def employee_name
    employee.name
  end

  def employee_email
    employee.email
  end

  def employee_department
    employee.department&.name
  end

  def formatted_review_date
    review_date.strftime("%B %d, %Y")
  end

  def rating_stars
    rating.to_i
  end

  def rating_decimal
    rating - rating.to_i
  end

  def rating_description
    case rating
    when 4.5..5.0
      "Outstanding"
    when 4.0..4.4
      "Excellent"
    when 3.5..3.9
      "Good"
    when 3.0..3.4
      "Satisfactory"
    when 2.5..2.9
      "Needs Improvement"
    else
      "Unsatisfactory"
    end
  end

  def rating_color
    case rating
    when 4.5..5.0
      "green"
    when 4.0..4.4
      "blue"
    when 3.5..3.9
      "yellow"
    when 3.0..3.4
      "orange"
    else
      "red"
    end
  end

  def goals_completed_count
    performance_goals.where(status: "completed").count
  end

  def goals_total_count
    performance_goals.count
  end

  def goals_completion_rate
    return 0 if goals_total_count == 0
    (goals_completed_count.to_f / goals_total_count * 100).round(1)
  end

  def achievements_list
    achievements&.split(",")&.map(&:strip) || []
  end

  def areas_for_improvement_list
    areas_for_improvement&.split(",")&.map(&:strip) || []
  end

  def goals_list
    goals&.split(",")&.map(&:strip) || []
  end

  def is_recent?
    review_date >= 6.months.ago
  end

  def is_overdue?
    # Assuming reviews should be done quarterly
    last_review = employee.performance_reviews.where("review_date < ?", review_date).order(review_date: :desc).first
    return false unless last_review
    review_date - last_review.review_date > 4.months
  end

  private

  def set_default_review_date
    self.review_date ||= Date.current
  end
end
