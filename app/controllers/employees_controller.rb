class EmployeesController < ApplicationController
  before_action :set_employee, only: [ :show, :update, :destroy ]

  def index
    @employees = Employee.includes(:manager, :department, :direct_reports)

    # Apply search filter
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @employees = @employees.where(
        "LOWER(employees.first_name) LIKE LOWER(?) OR LOWER(employees.last_name) LIKE LOWER(?) OR LOWER(employees.email) LIKE LOWER(?)",
        search_term, search_term, search_term
      )
    end

    # Apply department filter
    if params[:department].present? && params[:department] != "all"
      @employees = @employees.joins(:department).where(departments: { name: params[:department] })
    end

    # Get total count before pagination
    total_count = @employees.count

    # Apply pagination
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
    per_page = [per_page, 100].min # Cap at 100 per page

    @employees = @employees.order(:first_name, :last_name)
                           .offset((page - 1) * per_page)
                           .limit(per_page)

    total_pages = (total_count.to_f / per_page).ceil

    render json: {
      data: @employees.as_json(
        include: {
          manager: { only: [ :id, :first_name, :last_name, :email, :designation ] },
          department: { only: [ :id, :name ] },
          direct_reports: { only: [ :id, :first_name, :last_name, :email ] }
        }
      ),
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
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
