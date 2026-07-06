class EmployeeTrainingsController < ApplicationController
  before_action :set_employee_training, only: [ :show, :update, :destroy ]

  def index
    @employee_trainings = EmployeeTraining.includes(:employee).recent
    @employee_trainings = @employee_trainings.by_employee(params[:employee_id]) if params[:employee_id].present?
    @employee_trainings = @employee_trainings.by_status(params[:status]) if params[:status].present?
    render json: @employee_trainings.map { |t| format_training(t) }
  end

  def stats
    trainings = EmployeeTraining.all
    render json: {
      total: trainings.count,
      completed: trainings.completed.count,
      in_progress: trainings.in_progress.count,
      upcoming: trainings.upcoming.count,
      total_hours: trainings.completed.sum(:hours)
    }
  end

  def by_employee
    employee_id = params[:employee_id]
    return render json: { error: "employee_id is required" }, status: :bad_request if employee_id.blank?

    trainings = EmployeeTraining.includes(:employee).by_employee(employee_id).recent
    render json: trainings.map { |t| format_training(t) }
  end

  def current
    trainings = EmployeeTraining.includes(:employee).current.recent
    render json: trainings.map { |t| format_training(t) }
  end

  def upcoming
    trainings = EmployeeTraining.includes(:employee).upcoming.recent
    render json: trainings.map { |t| format_training(t) }
  end

  def update_progress
    @employee_training = EmployeeTraining.find(params[:id])
    if @employee_training.update(progress: params[:progress])
      render json: format_training(@employee_training)
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee training not found" }, status: :not_found
  end

  def complete
    @employee_training = EmployeeTraining.find(params[:id])
    if @employee_training.update(status: "completed", progress: 100)
      render json: format_training(@employee_training)
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee training not found" }, status: :not_found
  end

  def cancel
    @employee_training = EmployeeTraining.find(params[:id])
    if @employee_training.update(status: "cancelled")
      render json: format_training(@employee_training)
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee training not found" }, status: :not_found
  end

  def show
    render json: format_training(@employee_training)
  end

  def create
    @employee_training = EmployeeTraining.new(employee_training_params)
    if @employee_training.save
      render json: format_training(@employee_training), status: :created
    else
      render json: { errors: @employee_training.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @employee_training.update(employee_training_params)
      render json: format_training(@employee_training)
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

  def format_training(training)
    training.as_json.merge(
      "employee_name" => training.employee_name,
      "employee_department" => training.employee_department,
      "training_type_label" => training.training_type_label,
      "status_color" => training.status_color,
      "status_label" => training.status_label,
      "formatted_start_date" => training.formatted_start_date,
      "formatted_end_date" => training.formatted_end_date,
      "completion_status" => training.completion_status,
      "cost_formatted" => training.cost_formatted,
      "skills_list" => training.skills_list
    )
  end
end
