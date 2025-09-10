class AssetAllocationsController < ApplicationController
  before_action :set_allocation, only: [ :show, :update, :destroy, :return ]

  # GET /asset_allocations
  def index
    @allocations = AssetAllocation.includes(:asset, :employee)

    # Apply filters
    @allocations = @allocations.where(status: params[:status]) if params[:status].present?
    @allocations = @allocations.by_employee(params[:employee_id]) if params[:employee_id].present?
    @allocations = @allocations.by_asset(params[:asset_id]) if params[:asset_id].present?

    @allocations = @allocations.recent

    render json: {
      allocations: @allocations.map { |allocation| format_allocation(allocation) },
      total_count: @allocations.count,
      active_count: @allocations.active.count,
      returned_count: @allocations.returned.count
    }
  end

  # GET /asset_allocations/:id
  def show
    render json: {
      allocation: format_allocation(@allocation),
      asset: format_asset(@allocation.asset),
      employee: format_employee(@allocation.employee)
    }
  end

  # POST /asset_allocations
  def create
    @allocation = AssetAllocation.new(allocation_params)

    # Check if asset is available
    unless @allocation.asset.available?
      render json: {
        message: "Asset is not available for allocation",
        errors: [ "Asset is currently assigned or under maintenance" ]
      }, status: :unprocessable_entity
      return
    end

    if @allocation.save
      render json: {
        message: "Asset allocated successfully",
        allocation: format_allocation(@allocation)
      }, status: :created
    else
      render json: {
        message: "Failed to allocate asset",
        errors: @allocation.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /asset_allocations/:id
  def update
    if @allocation.update(allocation_params)
      render json: {
        message: "Allocation updated successfully",
        allocation: format_allocation(@allocation)
      }
    else
      render json: {
        message: "Failed to update allocation",
        errors: @allocation.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /asset_allocations/:id
  def destroy
    @allocation.destroy
    render json: { message: "Allocation deleted successfully" }
  end

  # PATCH /asset_allocations/:id/return
  def return
    return_date = params[:return_date] || Date.current
    notes = params[:notes]

    if @allocation.return_asset(return_date, notes)
      render json: {
        message: "Asset returned successfully",
        allocation: format_allocation(@allocation)
      }
    else
      render json: {
        message: "Failed to return asset",
        errors: @allocation.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_allocation
    @allocation = AssetAllocation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: "Allocation not found" }, status: :not_found
  end

  def allocation_params
    params.require(:asset_allocation).permit(
      :asset_id, :employee_id, :assigned_date, :return_date, :notes, :status
    )
  end

  def format_allocation(allocation)
    {
      id: allocation.id,
      asset_id: allocation.asset_id,
      asset_name: allocation.asset_name,
      asset_serial_number: allocation.asset_serial_number,
      asset_type: allocation.asset_type,
      employee_id: allocation.employee_id,
      employee_name: allocation.employee_name,
      employee_email: allocation.employee_email,
      employee_department: allocation.employee_department,
      assigned_date: allocation.assigned_date.strftime("%Y-%m-%d"),
      return_date: allocation.return_date&.strftime("%Y-%m-%d"),
      notes: allocation.notes,
      status: allocation.status,
      duration_days: allocation.duration_days,
      active: allocation.active?,
      returned: allocation.returned?,
      created_at: allocation.created_at,
      updated_at: allocation.updated_at
    }
  end

  def format_asset(asset)
    {
      id: asset.id,
      name: asset.name,
      asset_type: asset.asset_type,
      serial_number: asset.serial_number,
      model: asset.model,
      brand: asset.brand,
      status: asset.status,
      location: asset.location,
      department: asset.department,
      condition: asset.condition,
      current_value: asset.current_value
    }
  end

  def format_employee(employee)
    {
      id: employee.id,
      name: employee.name,
      email: employee.email,
      department: employee.department&.name,
      position: employee.position
    }
  end
end
