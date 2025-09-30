# frozen_string_literal: true

# app/controllers/interviews_controller.rb
class InterviewsController < ApplicationController
  before_action :set_interview, only: [ :show, :update, :destroy ]

  # GET /interviews
  def index
    @interviews = Interview.includes(:candidate)

    # Apply filters
    @interviews = @interviews.where(candidate_id: params[:candidate_id]) if params[:candidate_id].present?
    @interviews = @interviews.by_status(params[:status]) if params[:status].present?
    @interviews = @interviews.by_type(params[:interview_type]) if params[:interview_type].present?
    @interviews = @interviews.where(interviewer: params[:interviewer]) if params[:interviewer].present?

    # Date filters
    @interviews = @interviews.today if params[:today] == "true"
    @interviews = @interviews.this_week if params[:this_week] == "true"
    @interviews = @interviews.upcoming if params[:upcoming] == "true"
    @interviews = @interviews.past if params[:past] == "true"

    render json: @interviews.map { |interview| format_interview(interview) }
  end

  # GET /interviews/:id
  def show
    render json: format_interview(@interview)
  end

  # POST /interviews
  def create
    @interview = Interview.new(interview_params)
    @interview.status ||= "scheduled"

    if @interview.save!
      # Update candidate's last contact date
      @interview.candidate.update(last_contact: Date.current)

      render json: format_interview(@interview), status: :created
    else
      render json: { errors: @interview.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /interviews/:id
  def update
    if @interview.update(interview_params)
      render json: format_interview(@interview)
    else
      render json: { errors: @interview.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /interviews/:id
  def destroy
    @interview.destroy
    head :no_content
  end

  # PATCH /interviews/:id/complete
  def complete
    @interview = Interview.find(params[:id])

    if @interview.update(status: "completed", feedback: params[:feedback], rating: params[:rating])
      render json: format_interview(@interview)
    else
      render json: { errors: @interview.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /interviews/:id/cancel
  def cancel
    @interview = Interview.find(params[:id])

    if @interview.update(status: "cancelled", notes: params[:notes])
      render json: format_interview(@interview)
    else
      render json: { errors: @interview.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /interviews/:id/no_show
  def no_show
    @interview = Interview.find(params[:id])

    if @interview.update(status: "no_show", notes: params[:notes])
      render json: format_interview(@interview)
    else
      render json: { errors: @interview.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /interviews/stats
  def stats
    stats = {
      total_interviews: Interview.count,
      scheduled_interviews: Interview.scheduled.count,
      completed_interviews: Interview.completed.count,
      interviews_today: Interview.today.count,
      interviews_this_week: Interview.this_week.count,
      overdue_interviews: Interview.where("scheduled_date < ? AND status = ?", Date.current, "scheduled").count
    }

    # Interview type breakdown
    type_breakdown = {}
    Interview.group(:interview_type).count.each do |type, count|
      type_breakdown[type] = count
    end
    stats[:type_breakdown] = type_breakdown

    # Status breakdown
    status_breakdown = {}
    Interview.group(:status).count.each do |status, count|
      status_breakdown[status] = count
    end
    stats[:status_breakdown] = status_breakdown

    render json: stats
  end

  # GET /interviews/calendar
  def calendar
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current.end_of_month

    @interviews = Interview.where(scheduled_date: start_date..end_date).includes(:candidate)

    calendar_data = @interviews.map do |interview|
      {
        id: interview.id,
        title: "#{interview.candidate.name} - #{interview.interview_type.titleize}",
        start: interview.scheduled_datetime.iso8601,
        end: (interview.scheduled_datetime + 1.hour).iso8601,
        candidate_name: interview.candidate.name,
        interviewer: interview.interviewer,
        status: interview.status,
        type: interview.interview_type,
        color: interview_status_color(interview.status)
      }
    end

    render json: calendar_data
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def interview_params
    params.require(:interview).permit(:candidate_id, :interview_type, :scheduled_date, :scheduled_time, :interviewer, :status, :notes, :feedback, :rating)
  end

  def format_interview(interview)
    {
      id: interview.id,
      candidate_id: interview.candidate_id,
      candidate_name: interview.candidate.name,
      candidate_email: interview.candidate.email,
      interview_type: interview.interview_type,
      scheduled_date: interview.scheduled_date,
      scheduled_time: interview.scheduled_time,
      interviewer: interview.interviewer,
      status: interview.status,
      notes: interview.notes,
      feedback: interview.feedback,
      rating: interview.rating,
      is_today: interview.is_today?,
      is_overdue: interview.is_overdue?,
      is_upcoming: interview.is_upcoming?,
      formatted_time: interview.formatted_time,
      formatted_date: interview.formatted_date,
      status_color: interview.status_color,
      scheduled_datetime: interview.scheduled_datetime,
      created_at: interview.created_at,
      updated_at: interview.updated_at
    }
  end

  def interview_status_color(status)
    case status
    when "scheduled"
      "#3B82F6" # blue
    when "completed"
      "#10B981" # green
    when "cancelled"
      "#EF4444" # red
    when "no_show"
      "#F59E0B" # orange
    else
      "#6B7280" # gray
    end
  end
end
