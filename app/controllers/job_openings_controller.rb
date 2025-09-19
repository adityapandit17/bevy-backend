# frozen_string_literal: true

# app/controllers/job_openings_controller.rb
class JobOpeningsController < ApplicationController
  def index
    @job_openings = JobOpening.all
    render json: @job_openings
  end

  def show
    @job_opening = JobOpening.find(params[:id])
    render json: @job_opening
  end

  def create
    @job_opening = JobOpening.new(job_opening_params)
    if @job_opening.save
      render json: @job_opening, status: :created
    else
      render json: { errors: @job_opening.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @job_opening = JobOpening.find(params[:id])
    if @job_opening.update(job_opening_params)
      render json: @job_opening
    else
      render json: { errors: @job_opening.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @job_opening = JobOpening.find(params[:id])
    if @job_opening.update(status: "closed")
      render json: @job_opening
    else
      render json: { errors: @job_opening.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def job_opening_params
    params.require(:job_opening).permit(:title, :department_id, :description, :requirements, :status, :location, :job_type, :vacancies, :salary_min, :salary_max, :experience, :skills, :posted, :applications)
  end
end
