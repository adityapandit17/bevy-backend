# frozen_string_literal: true

class CompaniesController < ApplicationController
  include ActiveStorageUrlHelper

  skip_before_action :verify_authenticity_token, if: -> { request.format.json? || json_request? }

  before_action :set_company
  before_action :authorize_settings_show!, only: [ :show ]
  before_action :authorize_settings_update!, only: [ :update ]

  def show
    render json: company_json(@company)
  end

  def update
    @company.assign_attributes(company_params)
    handle_logo_on_update

    if @company.save
      render json: company_json(@company)
    else
      render json: { errors: @company.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
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
    params.require(:company).permit(
      :name, :code, :industry, :employee_count, :address, :timezone, :currency, :country_code,
      :weekly_working_hours, :work_start_time, :work_end_time, :lunch_duration_minutes,
      :dashboard_layout
    )
  end

  def handle_logo_on_update
    if ActiveModel::Type::Boolean.new.cast(params[:remove_logo])
      @company.remove_logo!
    elsif params[:logo].present?
      @company.attach_logo!(params[:logo])
    end
  end

  def company_json(company)
    company.as_json.merge(
      "logo_url" => active_storage_blob_url(company.logo),
      "careers_slug" => company.careers_slug,
      "careers_page_url" => company.careers_page_url
    )
  end

  def authorize_settings_show!
    authorize!("settings", "index")
  end

  def authorize_settings_update!
    authorize!("settings", "update")
  end
end
