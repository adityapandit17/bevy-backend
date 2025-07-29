class EmployeesController < ApplicationController
  def index
    @employees = Employee.all
    render json: @employees
  end

  def show
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
    @employee = Employee.find(params[:id])
    if @employee.update(employee_params)
      render json: @employee
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @employee = Employee.find(params[:id])
    if @employee.update(status: 'Inactive')
      render json: @employee
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def employee_params
      params.require(:employee).permit(:first_name, :last_name, :email, :phone, :department_id, :designation, :date_of_joining, :status)
    end
end
