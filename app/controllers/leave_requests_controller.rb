class LeaveRequestsController < ApplicationController
  def index
  end

  def show
  end

  def create
    @leave_request = LeaveRequest.new(leave_request_params)
    if @leave_request.save
      render json: @leave_request, status: :created
    else
      render json: { errors: @leave_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @leave_request.update(leave_request_params)
      render json: @leave_request
    else
      render json: { errors: @leave_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
  end
end
