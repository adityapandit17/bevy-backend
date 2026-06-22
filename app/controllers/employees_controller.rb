class EmployeesController < ApplicationController
  # Skip CSRF protection for JSON requests (handled by JWT authentication)
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? || json_request? }

  before_action :authenticate_user!
  before_action :set_employee, only: [ :show, :update, :destroy ]
  before_action :authorize_index!, only: [ :index ]
  before_action :authorize_show!, only: [ :show ]
  before_action :authorize_create!, only: [ :create ]
  before_action :authorize_update!, only: [ :update ]
  before_action :authorize_destroy!, only: [ :destroy ]

  def index
    @employees = Employee.includes(:manager, :department)

    # Apply search filter
    if params[:search].present?
      search_term = params[:search].strip
      # Split search term by spaces to handle full name searches
      search_parts = search_term.split(/\s+/).reject(&:blank?)

      if search_parts.length > 1
        # Multiple words: search for first word in first_name and last word in last_name (or vice versa)
        first_part = "%#{search_parts.first}%"
        last_part = "%#{search_parts.last}%"
        full_term = "%#{search_term}%"

        @employees = @employees.where(
          "(LOWER(employees.first_name) LIKE LOWER(?) AND LOWER(employees.last_name) LIKE LOWER(?)) OR " \
          "(LOWER(employees.first_name) LIKE LOWER(?) AND LOWER(employees.last_name) LIKE LOWER(?)) OR " \
          "LOWER(employees.email) LIKE LOWER(?)",
          first_part, last_part, last_part, first_part, full_term
        )
      else
        # Single word: search in first_name, last_name, or email
        single_term = "%#{search_term}%"
        @employees = @employees.where(
          "LOWER(employees.first_name) LIKE LOWER(?) OR LOWER(employees.last_name) LIKE LOWER(?) OR LOWER(employees.email) LIKE LOWER(?)",
          single_term, single_term, single_term
        )
      end
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
    per_page = [ per_page, 100 ].min # Cap at 100 per page

    @employees = @employees.order(:first_name, :last_name)
                           .offset((page - 1) * per_page)
                           .limit(per_page)

    total_pages = (total_count.to_f / per_page).ceil

    render json: {
      data: @employees.as_json(
        include: {
          manager: { only: [ :id, :first_name, :last_name, :email, :designation ] },
          department: { only: [ :id, :name ] }
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
    @employee = Employee.includes(:department, { manager: :department }, { direct_reports: :department })
                        .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee not found" }, status: :not_found
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :phone, :department_id, :designation, :date_of_joining, :status, :manager_id, :badge_level)
  end

  def authorize_index!
    authorize!("employees", "index")
  end

  def authorize_show!
    authorize!("employees", "show")
  end

  def authorize_create!
    # Allow Super Admin to create employees without explicit permission
    # return true if current_user&.super_admin?
    authorize!("employees", "create")
  end

  def authorize_update!
    authorize!("employees", "update")
  end

  def authorize_destroy!
    authorize!("employees", "destroy")
  end
end
