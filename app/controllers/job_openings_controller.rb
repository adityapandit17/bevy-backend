# frozen_string_literal: true

# app/controllers/job_openings_controller.rb
class JobOpeningsController < ApplicationController
  before_action :set_job_opening, only: [ :show, :update, :destroy ]

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
end
