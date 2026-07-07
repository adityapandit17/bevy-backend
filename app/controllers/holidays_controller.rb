# frozen_string_literal: true

class HolidaysController < ApplicationController
  before_action :set_holiday, only: [ :show, :update, :destroy ]
  before_action :authorize_holidays_manage!, only: [ :create, :update, :destroy ]

  def index
    holidays = Holiday.ordered

    if params[:year].present?
      holidays = holidays.for_year(params[:year])
    end

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      holidays = holidays.in_range(start_date, end_date)
    end

    render json: holidays.map { |holiday| format_holiday(holiday) }
  end

  def show
    render json: format_holiday(@holiday)
  end

  def create
    @holiday = Holiday.new(holiday_params)
    @holiday.created_by = current_user

    if @holiday.save
      render json: format_holiday(@holiday), status: :created
    else
      render json: { errors: @holiday.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @holiday.update(holiday_params)
      render json: format_holiday(@holiday)
    else
      render json: { errors: @holiday.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @holiday.destroy
    head :no_content
  end

  private

  def set_holiday
    @holiday = Holiday.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Holiday not found" }, status: :not_found
  end

  def holiday_params
    params.require(:holiday).permit(:date, :name, :reason)
  end

  def authorize_holidays_manage!
    authorize!("settings", "update")
  end

  def format_holiday(holiday)
    {
      id: holiday.id,
      date: holiday.date.iso8601,
      name: holiday.name,
      reason: holiday.reason,
      created_by: holiday.created_by ? {
        id: holiday.created_by.id,
        name: holiday.created_by.name
      } : nil,
      created_at: holiday.created_at,
      updated_at: holiday.updated_at
    }
  end
end
