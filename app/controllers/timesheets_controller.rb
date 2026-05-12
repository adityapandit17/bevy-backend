class TimesheetsController < ApplicationController
  before_action :set_timesheet, only: [ :show, :update, :destroy ]

  def index
    @timesheets = Timesheet.for_current_company
    render json: @timesheets
  end

  def show
    render json: @timesheet
  end

  def create
    @timesheet = Timesheet.new(timesheet_params)
    if @timesheet.save
      render json: @timesheet, status: :created
    else
      render json: { errors: @timesheet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @timesheet.update(timesheet_params)
      render json: @timesheet
    else
      render json: { errors: @timesheet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @timesheet.destroy
    head :no_content
  end

  private

  def set_timesheet
    @timesheet = find_in_tenant(Timesheet, params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def timesheet_params
    params.require(:timesheet).permit(:employee_id, :date, :hours, :project, :task, :status, :approved_by, :notes)
  end
end
