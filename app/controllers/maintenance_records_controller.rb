class MaintenanceRecordsController < ApplicationController
  before_action :set_maintenance_record, only: [ :show, :update, :destroy ]

  # GET /maintenance_records
  def index
    @maintenance_records = MaintenanceRecord.includes(:asset)

    # Apply filters
    @maintenance_records = @maintenance_records.by_type(params[:maintenance_type]) if params[:maintenance_type].present?
    @maintenance_records = @maintenance_records.by_performer(params[:performed_by]) if params[:performed_by].present?
    @maintenance_records = @maintenance_records.where("cost > ?", params[:min_cost]) if params[:min_cost].present?
    @maintenance_records = @maintenance_records.where("cost < ?", params[:max_cost]) if params[:max_cost].present?

    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @maintenance_records = @maintenance_records.where(
        maintenance_date: params[:start_date]..params[:end_date]
      )
    end

    @maintenance_records = @maintenance_records.recent

    render json: {
      maintenance_records: @maintenance_records.map { |record| format_maintenance_record(record) },
      total_count: @maintenance_records.count,
      total_cost: @maintenance_records.sum(:cost),
      average_cost: @maintenance_records.average(:cost)&.round(2) || 0,
      filters: {
        maintenance_types: MaintenanceRecord.distinct.pluck(:maintenance_type),
        performers: MaintenanceRecord.distinct.pluck(:performed_by)
      }
    }
  end

  # GET /maintenance_records/:id
  def show
    render json: {
      maintenance_record: format_maintenance_record(@maintenance_record),
      asset: format_asset(@maintenance_record.asset)
    }
  end

  # POST /maintenance_records
  def create
    @maintenance_record = MaintenanceRecord.new(maintenance_record_params)

    if @maintenance_record.save
      render json: {
        message: "Maintenance record created successfully",
        maintenance_record: format_maintenance_record(@maintenance_record)
      }, status: :created
    else
      render json: {
        message: "Failed to create maintenance record",
        errors: @maintenance_record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /maintenance_records/:id
  def update
    if @maintenance_record.update(maintenance_record_params)
      render json: {
        message: "Maintenance record updated successfully",
        maintenance_record: format_maintenance_record(@maintenance_record)
      }
    else
      render json: {
        message: "Failed to update maintenance record",
        errors: @maintenance_record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /maintenance_records/:id
  def destroy
    @maintenance_record.destroy
    render json: { message: "Maintenance record deleted successfully" }
  end

  # POST /maintenance_records/schedule
  def schedule
    asset_id = params[:asset_id]
    maintenance_type = params[:maintenance_type]
    scheduled_date = params[:scheduled_date]
    notes = params[:notes]

    asset = Asset.find(asset_id)

    # Create a scheduled maintenance record
    @maintenance_record = MaintenanceRecord.new(
      asset: asset,
      maintenance_type: maintenance_type,
      maintenance_date: scheduled_date,
      description: notes || "Scheduled #{maintenance_type} maintenance",
      cost: 0,
      performed_by: "Scheduled"
    )

    if @maintenance_record.save
      render json: {
        message: "Maintenance scheduled successfully",
        maintenance_record: format_maintenance_record(@maintenance_record)
      }, status: :created
    else
      render json: {
        message: "Failed to schedule maintenance",
        errors: @maintenance_record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_maintenance_record
    @maintenance_record = MaintenanceRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: "Maintenance record not found" }, status: :not_found
  end

  def maintenance_record_params
    params.require(:maintenance_record).permit(
      :asset_id, :maintenance_date, :maintenance_type, :description,
      :cost, :performed_by, :next_maintenance
    )
  end

  def format_maintenance_record(record)
    {
      id: record.id,
      asset_id: record.asset_id,
      asset_name: record.asset_name,
      asset_serial_number: record.asset_serial_number,
      asset_type: record.asset_type,
      maintenance_date: record.maintenance_date.strftime("%Y-%m-%d"),
      maintenance_type: record.maintenance_type,
      description: record.description,
      cost: record.cost,
      performed_by: record.performed_by,
      next_maintenance: record.next_maintenance&.strftime("%Y-%m-%d"),
      type_color: record.type_color,
      cost_category: record.cost_category,
      expensive: record.expensive?,
      overdue: record.overdue?,
      due_soon: record.due_soon?,
      maintenance_type_label: record.maintenance_type_label,
      formatted_cost: record.formatted_cost,
      formatted_date: record.formatted_date,
      formatted_next_maintenance: record.formatted_next_maintenance,
      created_at: record.created_at,
      updated_at: record.updated_at
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
      current_value: asset.current_value,
      last_maintenance: asset.last_maintenance&.strftime("%Y-%m-%d"),
      next_maintenance: asset.next_maintenance&.strftime("%Y-%m-%d")
    }
  end
end
