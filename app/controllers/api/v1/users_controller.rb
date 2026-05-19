# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  # GET /api/v1/users/directory
  # Minimal user list for chat / mentions — any authenticated user (no users.index required).
  def directory
    users = User.active
                .includes(:employee)
                .where.not(id: current_user.id)
                .order(:first_name, :last_name)

    if params[:search].present?
      term = "%#{params[:search].to_s.strip}%"
      users = users.where(
        "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
        term, term, term
      )
    end

    render json: {
      success: true,
      users: users.map { |user| format_directory_user(user) }
    }
  end

  private

  def format_directory_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      employee_id: user.employee_id
    }
  end
end
