class CompaniesController < ApplicationController
  before_action :set_company

  def show
    render json: @company
  end

  def update
    authorize!("settings", "update")
    if @company.update(company_params)
      render json: @company
    else
      render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.first || Company.create!(
      name: "Default Company",
      code: "DEF",
      industry: "General",
      employee_count: "0",
      timezone: "UTC",
      currency: "USD"
    )
  end

  def company_params
    params.require(:company).permit(:name, :code, :industry, :employee_count, :address, :timezone, :currency)
  end
end
