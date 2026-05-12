class DepartmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @departments = Department.for_current_company
    render json: @departments
  end

  def show
    @department = find_in_tenant(Department, params[:id])
    render json: @department
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Department not found" }, status: :not_found
  end

  def create
    @department = Department.new(department_params)
    if @department.save
      render json: @department, status: :created
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @department = find_in_tenant(Department, params[:id])
    if @department.update(department_params)
      render json: @department
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Department not found" }, status: :not_found
  end

  def destroy
    @department = find_in_tenant(Department, params[:id])
    if @department.employees.any? || @department.job_openings.any?
      render json: { error: "Cannot delete department with associated employees or job openings" }, status: :unprocessable_entity
    else
      @department.destroy
      head :no_content
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Department not found" }, status: :not_found
  end

  private

  def department_params
    params.require(:department).permit(:name)
  end
end
