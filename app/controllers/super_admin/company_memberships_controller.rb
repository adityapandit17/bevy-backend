# frozen_string_literal: true

class SuperAdmin::CompanyMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_super_admin!
  before_action :set_membership, only: [ :destroy ]

  def index
    scope = CompanyMembership.includes(:user, :company)
    scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?

    render json: {
      success: true,
      data: scope.order(:id).map { |m| membership_json(m) }
    }
  end

  def create
    membership = CompanyMembership.new(membership_params)
    if membership.save
      render json: { success: true, data: membership_json(membership) }, status: :created
    else
      render json: { success: false, error: membership.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @membership.destroy!
    head :no_content
  end

  private

  def set_membership
    @membership = CompanyMembership.find(params[:id])
  end

  def membership_params
    params.require(:company_membership).permit(:company_id, :user_id, :status, :role)
  end

  def membership_json(m)
    {
      id: m.id,
      company_id: m.company_id,
      user_id: m.user_id,
      status: m.status,
      role: m.role,
      company_name: m.company&.name,
      user_email: m.user&.email,
      created_at: m.created_at,
      updated_at: m.updated_at
    }
  end
end
