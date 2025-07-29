class PayrollsController < ApplicationController
  def index
  end

  def show
  end

  def create
    @payroll = Payroll.new(payroll_params)
    if @payroll.save
      render json: @payroll, status: :created
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @payroll.update(payroll_params)
      render json: @payroll
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
  end
end
