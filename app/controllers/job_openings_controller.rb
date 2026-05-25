# frozen_string_literal: true

# app/controllers/job_openings_controller.rb
class JobOpeningsController < ApplicationController
  # Skip CSRF protection for JSON API requests
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

  before_action :authenticate_user!
  before_action :set_job_opening, only: [ :show, :update, :destroy, :candidates ]
  before_action :authorize_index!, only: [ :index ]
  before_action :authorize_show!, only: [ :show, :candidates ]
  before_action :authorize_create!, only: [ :create ]
  before_action :authorize_update!, only: [ :update ]
  before_action :authorize_destroy!, only: [ :destroy ]

  def index
    @job_openings = JobOpening.includes(:department).all

    if params[:search].present?
      @job_openings = @job_openings.search(params[:search])
    end

    render json: Panko::ArraySerializer.new(@job_openings, each_serializer: JobOpeningSerializer).to_json
  end

  def show
    render json: JobOpeningSerializer.new.serialize(@job_opening)
  end

  # GET /job_openings/:id/candidates
  def candidates
    authorize!("candidates", "index")

    dept_name = @job_opening.department&.name
    scope = Candidate.not_archived.where(
      "job_opening_id = :job_id OR (job_opening_id IS NULL AND position = :title AND department = :dept)",
      job_id: @job_opening.id,
      title: @job_opening.title,
      dept: dept_name
    )
    scope = scope.search_text(params[:search]) if params[:search].present?
    scope = scope.with_skills(params[:skills]) if params[:skills].present?
    scope = scope.applied_on_or_after(params[:applied_from]) if params[:applied_from].present?
    scope = scope.applied_on_or_before(params[:applied_to]) if params[:applied_to].present?

    candidates = scope.order(applied_date: :desc, created_at: :desc)
    render json: Panko::ArraySerializer.new(candidates, each_serializer: CandidateSerializer).to_json
  end

  def create
    @job_opening = JobOpening.new(job_opening_params)
    if @job_opening.save
      render json: JobOpeningSerializer.new.serialize(@job_opening), status: :created
    else
      render_error(@job_opening.errors.full_messages)
    end
  end

  def update
    if @job_opening.update(job_opening_params)
      render json: JobOpeningSerializer.new.serialize(@job_opening)
    else
      render_error(@job_opening.errors.full_messages)
    end
  end

  def destroy
    if @job_opening.update(status: "closed")
      render json: JobOpeningSerializer.new.serialize(@job_opening)
    else
      render_error(@job_opening.errors.full_messages)
    end
  end

  private

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def set_job_opening
    @job_opening = JobOpening.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Job opening not found" }, status: :not_found
  end

  def job_opening_params
    params.require(:job_opening)
          .permit(:title, :department_id, :description,
                  :requirements, :status, :location, :job_type,
                  :vacancies, :salary_min, :salary_max, :experience,
                  :skills, :posted, :applications)
  end

  def authorize_index!
    authorize!("job_openings", "index")
  end

  def authorize_show!
    authorize!("job_openings", "show")
  end

  def authorize_create!
    authorize!("job_openings", "create")
  end

  def authorize_update!
    authorize!("job_openings", "update")
  end

  def authorize_destroy!
    authorize!("job_openings", "destroy")
  end
end
