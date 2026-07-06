# frozen_string_literal: true

class WorkspaceSeatsController < ApplicationController
  before_action :set_workspace_seat, only: [ :show, :update, :destroy ]

  def index
    ensure_default_seats! if WorkspaceSeat.none?

    seats = WorkspaceSeat.includes(employee: :department).by_zone(params[:zone])
    if params[:search].present?
      q = "%#{params[:search].downcase}%"
      seats = seats.left_joins(:employee).where(
        "LOWER(workspace_seats.label) LIKE :q OR LOWER(employees.first_name) LIKE :q OR LOWER(employees.last_name) LIKE :q",
        q: q
      )
    end

    render json: seats.map { |seat| format_seat(seat) }
  end

  def show
    render json: format_seat(@workspace_seat)
  end

  def update
    if @workspace_seat.update(workspace_seat_params)
      render json: format_seat(@workspace_seat)
    else
      render json: { errors: @workspace_seat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    seat = WorkspaceSeat.new(workspace_seat_params)
    if seat.save
      render json: format_seat(seat), status: :created
    else
      render json: { errors: seat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @workspace_seat.destroy
    head :no_content
  end

  def stats
    render json: {
      total: WorkspaceSeat.count,
      occupied: WorkspaceSeat.where(status: "occupied").count,
      vacant: WorkspaceSeat.where(status: "vacant").count,
      blocked: WorkspaceSeat.where(status: "blocked").count
    }
  end

  private

  def set_workspace_seat
    @workspace_seat = WorkspaceSeat.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Seat not found" }, status: :not_found
  end

  def workspace_seat_params
    params.require(:workspace_seat).permit(:label, :zone, :status, :employee_id)
  end

  def format_seat(seat)
    {
      id: seat.id,
      label: seat.label,
      zone: seat.zone,
      status: seat.status,
      employee_id: seat.employee_id,
      employee_name: seat.employee_name,
      employee_department: seat.employee_department
    }
  end

  def ensure_default_seats!
    zones = {
      "north" => "N",
      "center" => "C",
      "south" => "S"
    }
    zones.each do |zone, prefix|
      30.times do |i|
        label = "#{prefix}-#{format('%02d', i + 1)}"
        WorkspaceSeat.create!(label: label, zone: zone, status: "vacant")
      end
    end
  end
end
