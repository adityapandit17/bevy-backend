class CompaniesController < ApplicationController
  before_action :set_company

  def show
    render json: @company
  end

  def update
    if @company.update(company_params)
      render json: @company
    else
      render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.first
  end

  def company_params
    params.require(:company).permit(:name, :address, :phone, :email)
  end
end
