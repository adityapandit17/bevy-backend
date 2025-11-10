class LeavePoliciesController < ApplicationController
  before_action :set_leave_policy, only: [ :show, :update, :destroy ]

  def index
    @policies = LeavePolicy.order(year: :desc)
    render json: @policies.map { |policy| format_leave_policy(policy) }
  end

  def show
    render json: format_leave_policy(@leave_policy)
  end

  def current
    @policy = LeavePolicy.current_policy
    render json: format_leave_policy(@policy)
  end

  def create
    @leave_policy = LeavePolicy.new(leave_policy_params)

    if @leave_policy.save
      render json: format_leave_policy(@leave_policy), status: :created
    else
      render json: { errors: @leave_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @leave_policy.update(leave_policy_params)
      render json: format_leave_policy(@leave_policy)
    else
      render json: { errors: @leave_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @leave_policy.destroy
    head :no_content
  end

  private

  def set_leave_policy
    @leave_policy = LeavePolicy.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Leave policy not found" }, status: :not_found
  end

  def leave_policy_params
    params.require(:leave_policy).permit(
      :year,
      :holidays_per_year,
      :annual_leave,
      :sick_leave,
      :personal_leave,
      :maternity_leave,
      :paternity_leave,
      :unpaid_leave,
      :other_leave,
      :active
    )
  end

  def format_leave_policy(policy)
    {
      id: policy.id,
      year: policy.year,
      holidays_per_year: policy.holidays_per_year,
      annual_leave: policy.annual_leave,
      sick_leave: policy.sick_leave,
      personal_leave: policy.personal_leave,
      maternity_leave: policy.maternity_leave,
      paternity_leave: policy.paternity_leave,
      unpaid_leave: policy.unpaid_leave,
      other_leave: policy.other_leave,
      active: policy.active,
      created_at: policy.created_at,
      updated_at: policy.updated_at
    }
  end
end
