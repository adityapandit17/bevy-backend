class EmployeeBenefitsController < ApplicationController
  before_action :set_employee_benefit, only: [ :show, :update, :destroy ]

  def index
    @employee_benefits = EmployeeBenefit.for_current_company
    render json: @employee_benefits
  end

  def show
    render json: @employee_benefit
  end

  def create
    @employee_benefit = EmployeeBenefit.new(employee_benefit_params)
    if @employee_benefit.save
      render json: @employee_benefit, status: :created
    else
      render json: { errors: @employee_benefit.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @employee_benefit.update(employee_benefit_params)
      render json: @employee_benefit
    else
      render json: { errors: @employee_benefit.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @employee_benefit.destroy
    head :no_content
  end

  private

  def set_employee_benefit
    @employee_benefit = find_in_tenant(EmployeeBenefit, params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee benefit not found" }, status: :not_found
  end

  def employee_benefit_params
    params.require(:employee_benefit).permit(:employee_id, :name, :benefit_type, :provider, :coverage, :cost, :start_date, :end_date, :status)
  end
end
