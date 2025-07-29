class AttendanceRecordsController < ApplicationController
  def index
  end

  def show
  end

  def create
    @attendance_record = AttendanceRecord.new(attendance_record_params)
    if @attendance_record.save
      render json: @attendance_record, status: :created
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @attendance_record.update(attendance_record_params)
      render json: @attendance_record
    else
      render json: { errors: @attendance_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
  end
end
