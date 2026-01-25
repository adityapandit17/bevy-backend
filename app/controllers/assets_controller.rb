class AssetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_asset, only: [ :show, :update, :destroy ]
  before_action :authorize_index!, only: [ :index ]
  before_action :authorize_show!, only: [ :show ]
  before_action :authorize_create!, only: [ :create ]
  before_action :authorize_update!, only: [ :update ]
  before_action :authorize_destroy!, only: [ :destroy ]

  # GET /assets
  def index
    @assets = Asset.includes(:employee)

    # Apply filters
    @assets = @assets.by_type(params[:asset_type]) if params[:asset_type].present?
    @assets = @assets.by_department(params[:department]) if params[:department].present?
    @assets = @assets.by_condition(params[:condition]) if params[:condition].present?
    @assets = @assets.where(status: params[:status]) if params[:status].present?

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @assets = @assets.where(
        "assets.name ILIKE ? OR assets.serial_number ILIKE ? OR assets.brand ILIKE ? OR assets.model ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    @assets = @assets.order(created_at: :desc)

    render json: {
      assets: @assets.map { |asset| format_asset(asset) },
      total_count: @assets.size,
      filters: {
        asset_types: Asset.distinct.pluck(:asset_type),
        departments: Asset.distinct.pluck(:department),
        conditions: Asset.distinct.pluck(:condition),
        statuses: Asset.distinct.pluck(:status)
      }
    }
  end

  # GET /assets/:id
  def show
    render json: {
      asset: format_asset(@asset),
      maintenance_history: @asset.maintenance_records.order(maintenance_date: :desc).map { |record| format_maintenance_record(record) },
      allocation_history: @asset.asset_allocations.map { |allocation| format_allocation(allocation) }
    }
  end

  # POST /assets
  def create
    @asset = Asset.new(asset_params)

    if @asset.save
      render json: {
        message: "Asset created successfully",
        asset: format_asset(@asset)
      }, status: :created
    else
      render json: {
        message: "Failed to create asset",
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /assets/:id
  def update
    if @asset.update(asset_params)
      render json: {
        message: "Asset updated successfully",
        asset: format_asset(@asset)
      }
    else
      render json: {
        message: "Failed to update asset",
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /assets/:id
  def destroy
    @asset.destroy
    render json: { message: "Asset deleted successfully" }
  end

  # GET /assets/stats
  def stats
    total_assets = Asset.count
    assigned_assets = Asset.assigned.size
    available_assets = Asset.available.size
    maintenance_assets = Asset.maintenance.size
    total_value = Asset.sum(:current_value)
    purchase_value = Asset.sum(:purchase_cost)

    asset_types = Asset.group(:asset_type).size
    status_distribution = Asset.group(:status).size
    condition_distribution = Asset.group(:condition).size
    department_distribution = Asset.group(:department).size

    overdue_maintenance = Asset.overdue_maintenance.size
    due_maintenance_soon = Asset.due_maintenance_soon.size
    warranty_expiring_soon = Asset.warranty_expiring_soon.size

    render json: {
      overview: {
        total_assets: total_assets,
        assigned_assets: assigned_assets,
        available_assets: available_assets,
        maintenance_assets: maintenance_assets,
        utilization_rate: total_assets > 0 ? (assigned_assets.to_f / total_assets * 100).round(1) : 0
      },
      financial: {
        total_value: total_value || 0,
        purchase_value: purchase_value || 0,
        depreciation: (purchase_value || 0) - (total_value || 0),
        average_asset_age: begin
          assets_with_dates = Asset.where.not(purchase_date: nil)
          if assets_with_dates.exists?
            # PostgreSQL: Calculate average age in years
            avg = assets_with_dates.average("EXTRACT(YEAR FROM AGE(CURRENT_DATE, purchase_date))")
            avg ? avg.round(1) : 0.0
          else
            0.0
          end
        end
      },
      distribution: {
        asset_types: asset_types,
        status: status_distribution,
        condition: condition_distribution,
        departments: department_distribution
      },
      maintenance: {
        overdue_maintenance: overdue_maintenance,
        due_maintenance_soon: due_maintenance_soon,
        warranty_expiring_soon: warranty_expiring_soon
      }
    }
  end

  # GET /assets/allocations
  def allocations
    @allocations = AssetAllocation.includes(:asset, :employee).active.recent

    render json: {
      allocations: @allocations.map { |allocation| format_allocation(allocation) },
      total_active_allocations: @allocations.size
    }
  end

  # GET /assets/maintenance
  def maintenance
    @maintenance_records = MaintenanceRecord.includes(:asset).recent.limit(20)
    @overdue_assets = Asset.overdue_maintenance.includes(:employee)
    @due_soon_assets = Asset.due_maintenance_soon.includes(:employee)

    render json: {
      recent_maintenance: @maintenance_records.map { |record| format_maintenance_record(record) },
      overdue_maintenance: @overdue_assets.map { |asset| format_asset(asset) },
      due_maintenance_soon: @due_soon_assets.map { |asset| format_asset(asset) },
      maintenance_stats: {
        total_maintenance_cost: MaintenanceRecord.sum(:cost),
        maintenance_count_this_year: MaintenanceRecord.this_year.size,
        average_maintenance_cost: MaintenanceRecord.average(:cost)&.round(2) || 0
      }
    }
  end

  private

  def set_asset
    @asset = Asset.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: "Asset not found" }, status: :not_found
  end

  def asset_params
    params.require(:asset).permit(
      :name, :asset_type, :serial_number, :model, :brand,
      :purchase_date, :warranty_expiry, :purchase_cost, :current_value,
      :status, :location, :department, :notes, :condition,
      :last_maintenance, :next_maintenance, :employee_id
    )
  end

  def format_asset(asset)
    {
      id: asset.id,
      name: asset.name,
      asset_type: asset.asset_type,
      serial_number: asset.serial_number,
      model: asset.model,
      brand: asset.brand,
      purchase_date: asset.purchase_date&.strftime("%Y-%m-%d"),
      warranty_expiry: asset.warranty_expiry&.strftime("%Y-%m-%d"),
      purchase_cost: asset.purchase_cost,
      current_value: asset.current_value,
      status: asset.status,
      location: asset.location,
      department: asset.department,
      notes: asset.notes,
      condition: asset.condition,
      last_maintenance: asset.last_maintenance&.strftime("%Y-%m-%d"),
      next_maintenance: asset.next_maintenance&.strftime("%Y-%m-%d"),
      assigned_to: asset.employee ? {
        id: asset.employee.id,
        name: asset.employee.name,
        email: asset.employee.email,
        department: asset.employee.department&.name
      } : nil,
      created_at: asset.created_at,
      updated_at: asset.updated_at
    }
  end

  def format_maintenance_record(record)
    {
      id: record.id,
      maintenance_date: record.maintenance_date.strftime("%Y-%m-%d"),
      maintenance_type: record.maintenance_type,
      description: record.description,
      cost: record.cost,
      performed_by: record.performed_by,
      next_maintenance: record.next_maintenance&.strftime("%Y-%m-%d"),
      asset_name: record.asset.name,
      asset_serial_number: record.asset.serial_number,
      created_at: record.created_at
    }
  end

  def format_allocation(allocation)
    {
      id: allocation.id,
      asset_id: allocation.asset_id,
      asset_name: allocation.asset.name,
      asset_serial_number: allocation.asset.serial_number,
      asset_type: allocation.asset.asset_type,
      employee_id: allocation.employee_id,
      employee_name: allocation.employee.name,
      employee_email: allocation.employee.email,
      employee_department: allocation.employee.department&.name,
      assigned_date: allocation.assigned_date.strftime("%Y-%m-%d"),
      return_date: allocation.return_date&.strftime("%Y-%m-%d"),
      notes: allocation.notes,
      status: allocation.status,
      created_at: allocation.created_at
    }
  end

  def authorize_index!
    authorize!("assets", "index")
  end

  def authorize_show!
    authorize!("assets", "show")
  end

  def authorize_create!
    authorize!("assets", "create")
  end

  def authorize_update!
    authorize!("assets", "update")
  end

  def authorize_destroy!
    authorize!("assets", "destroy")
  end
end
