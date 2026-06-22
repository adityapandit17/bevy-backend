class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_report!

  # GET /reports/:type
  def show
    payload = Reports::Generator.new(type: params[:type], params: report_params).generate
    render json: { success: true, data: payload }
  rescue ArgumentError => e
    render json: { success: false, error: e.message }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Report error (#{params[:type]}): #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render json: { success: false, error: "Failed to generate report" }, status: :internal_server_error
  end

  private

  def authorize_report!
    authorize!("reports", "index")
  end

  def report_params
    params.permit(:period, :start_date, :end_date, :month, :year, :date)
  end
end
