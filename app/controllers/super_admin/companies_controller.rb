# frozen_string_literal: true

class SuperAdmin::CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_super_admin!
  before_action :set_company, only: [ :show, :update, :destroy ]

  def index
    companies = Company.order(:name)
    render json: { success: true, data: companies.map { |c| company_json(c) } }
  end

  def show
    render json: { success: true, data: company_json(@company) }
  end

  def create
    company = Company.new(company_params)
    if company.save
      render json: { success: true, data: company_json(company) }, status: :created
    else
      render json: { success: false, error: company.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def update
    if @company.update(company_params)
      render json: { success: true, data: company_json(@company) }
    else
      render json: { success: false, error: @company.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(
      :name, :code, :industry, :employee_count, :address, :timezone, :currency, :country_code
    )
  end

  def company_json(company)
    company.as_json(
      only: %i[
        id name code industry timezone currency country_code address employee_count created_at updated_at
      ]
    )
  end
end
