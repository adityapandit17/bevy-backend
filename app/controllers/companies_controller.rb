class CompaniesController < ApplicationController
  before_action :authenticate_user!
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
    unless Current.company
      return render json: { success: false, error: "Workspace context required" }, status: :unprocessable_entity
    end

    @company = Current.company
  end

  def company_params
    params.require(:company).permit(:name, :code, :industry, :employee_count, :address, :timezone, :currency, :country_code)
  end
end
