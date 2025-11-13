class EmployeesController < ApplicationController
  before_action :set_employee, only: [ :show, :update, :destroy ]

  def index
    @employees = Employee.includes(:manager, :department, :direct_reports).all
    render json: @employees.as_json(
      include: {
        manager: { only: [ :id, :first_name, :last_name, :email, :designation ] },
        department: { only: [ :id, :name ] },
        direct_reports: { only: [ :id, :first_name, :last_name, :email ] }
      }
    )
  end

  def show
    render json: EmployeeSerializer.new.serialize(@employee)
  end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      render json: @employee, status: :created
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @employee.update(employee_params)
      render json: @employee
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @employee.update(status: "inactive")
      render json: @employee
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee not found" }, status: :not_found
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :phone, :department_id, :designation, :date_of_joining, :status, :manager_id)
  end
end
