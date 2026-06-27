class DepartmentsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? || json_request? }

  before_action :authenticate_user!
  before_action :authorize_manage!, only: [ :create, :update, :destroy, :seed_defaults ]
  before_action :set_department, only: [ :show, :update, :destroy ]

  def index
    @departments = Department.left_joins(:employees)
                             .select("departments.*, COUNT(employees.id) AS employee_count")
                             .group("departments.id")
                             .order(:name)
    render json: @departments.map { |dept| format_department(dept) }
  end

  def defaults
    existing = Department.where(name: DepartmentSeeder.default_names).pluck(:name)
    missing = DepartmentSeeder.default_names - existing

    render json: {
      default_names: DepartmentSeeder.default_names,
      existing: existing,
      missing: missing
    }
  end

  def seed_defaults
    created = DepartmentSeeder.seed!
    render json: {
      message: "Default departments added",
      departments: created.map { |dept| format_department(dept) }
    }
  end

  def show
    render json: format_department(@department)
  end

  def create
    @department = Department.new(department_params)
    if @department.save
      render json: format_department(@department), status: :created
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @department.update(department_params)
      render json: format_department(@department)
    else
      render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @department.employees.any? || @department.job_openings.any?
      render json: { error: "Cannot delete department with associated employees or job openings" }, status: :unprocessable_entity
    else
      @department.destroy
      head :no_content
    end
  end

  private

  def set_department
    @department = Department.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Department not found" }, status: :not_found
  end

  def authorize_manage!
    authorize!("settings", "update")
  end

  def department_params
    params.require(:department).permit(:name)
  end

  def format_department(department)
    count = department.respond_to?(:employee_count) ? department.employee_count.to_i : department.employees.count

    {
      id: department.id,
      name: department.name,
      employee_count: count,
      created_at: department.created_at,
      updated_at: department.updated_at
    }
  end
end
