class ReturnAssetAllocationsController < ApplicationController
  before_action :set_allocation

  def update
    if @allocation.return_asset(allocation_params[:return_date], allocation_params[:notes])
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
    @allocation = find_in_tenant(AssetAllocation, params[:asset_allocation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: "Allocation not found" }, status: :not_found
  end

  def allocation_params
    params.require(:return_asset_allocation).permit(
      :return_date, :notes
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
end
