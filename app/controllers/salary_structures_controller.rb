class SalaryStructuresController < ApplicationController
  before_action :set_salary_structure, only: [ :show, :update, :destroy ]

  def index
    @salary_structures = SalaryStructure.all
    render json: @salary_structures
  end

  def show
    render json: @salary_structure
  end

  def create
    @salary_structure = SalaryStructure.new(salary_structure_params)
    if @salary_structure.save
      render json: @salary_structure, status: :created
    else
      render json: { errors: @salary_structure.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @salary_structure.update(salary_structure_params)
      render json: @salary_structure
    else
      render json: { errors: @salary_structure.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @salary_structure.destroy
    head :no_content
  end

  # Generate default salary structures for an employee or all employees
  def generate_defaults
    if params[:employee_id].present?
      employee = Employee.find(params[:employee_id])
      created = SalaryStructure.generate_defaults_for_employee(employee)
      render json: {
        message: "Generated #{created.size} default salary structure(s) for employee #{employee.id}",
        created_count: created.size,
        structures: created
      }, status: :ok
    else
      created = SalaryStructure.generate_defaults_for_all_employees
      render json: {
        message: "Generated #{created.size} default salary structure(s) for all employees",
        created_count: created.size
      }, status: :ok
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Get complete salary structures for an employee (with defaults)
  def complete_structures
    employee = Employee.find(params[:employee_id])
    structures = SalaryStructure.complete_structures_for_employee(employee)
    render json: structures
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  def set_salary_structure
    @salary_structure = SalaryStructure.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Salary structure not found" }, status: :not_found
  end

  def salary_structure_params
    params.require(:salary_structure).permit(
      :employee_id,
      :department_id,
      :level,
      :basic,
      :hra,
      :allowances,
      :bonus,
      :deductions,
      :pf,
      :esi,
      :professional_tax,
      :income_tax,
      :effective_from,
      :effective_upto
    )
  end
end
