class EmployeeTrainingsController < ApplicationController
  before_action :set_employee_training, only: [ :show, :update, :destroy ]

  def index
    @employee_trainings = EmployeeTraining.all
    render json: @employee_trainings
  end

  def show
    render json: @employee_training
  end

  def create
    @employee_training = EmployeeTraining.new(employee_training_params)
    if @employee_training.save
      render json: @employee_training, status: :created
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @employee_training.update(employee_training_params)
      render json: @employee_training
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @employee_training.destroy
    head :no_content
  end

  private

  def set_employee_training
    @employee_training = EmployeeTraining.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee training not found" }, status: :not_found
  end

  def employee_training_params
    params.require(:employee_training).permit(:employee_id, :name, :training_type, :provider, :start_date, :end_date, :status, :progress, :certificate, :cost, :skills, :hours)
  end
end
