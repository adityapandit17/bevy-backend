module Api
  class AssetsController < ApplicationController
    include AssetApiFormatting

    before_action :set_asset, only: [ :show, :update, :destroy, :qr_code, :barcode, :label ]

    # GET /api/assets
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
          "assets.name ILIKE ? OR assets.serial_number ILIKE ? OR assets.asset_tag ILIKE ? OR assets.brand ILIKE ? OR assets.model ILIKE ?",
          search_term, search_term, search_term, search_term, search_term
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

    # GET /api/assets/:id
    def show
      render json: {
        asset: format_asset(@asset),
        maintenance_history: @asset.maintenance_records.order(maintenance_date: :desc).map { |record| format_maintenance_record(record) },
        allocation_history: @asset.asset_allocations.map { |allocation| format_allocation(allocation) }
      }
    end

    # GET /api/assets/lookup?code=...
    def lookup
      code = params[:code].presence || params[:tag].presence
      if code.blank?
        render json: { message: "Scan code is required" }, status: :bad_request
        return
      end

      asset = Asset.find_by_scan_code(code)
      if asset
        render json: { asset: format_asset(asset) }
      else
        render json: { message: "Asset not found for scan code" }, status: :not_found
      end
    end

    # GET /api/assets/:id/label
    def label
      service = AssetLabelService.new(@asset)
      render json: {
        label: service.label_metadata(base_url: request.base_url),
        qr_code_data_url: png_data_url(service.qr_png),
        barcode_data_url: png_data_url(service.barcode_png)
      }
    end

    # GET /api/assets/:id/qr_code
    def qr_code
      send_png(AssetLabelService.new(@asset).qr_png, filename: "#{@asset.asset_tag}-qr.png")
    end

    # GET /api/assets/:id/barcode
    def barcode
      send_png(AssetLabelService.new(@asset).barcode_png, filename: "#{@asset.asset_tag}-barcode.png")
    end

    # POST /api/assets
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

    # PATCH/PUT /api/assets/:id
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

    # DELETE /api/assets/:id
    def destroy
      @asset.destroy
      render json: { message: "Asset deleted successfully" }
    end

    # GET /api/assets/stats
    def stats
      total_assets = Asset.count
      assigned_assets = Asset.assigned.size
      available_assets = Asset.available.size
      maintenance_assets = Asset.maintenance.size
      total_value = Asset.sum(:current_value) || 0
      purchase_value = Asset.sum(:purchase_cost) || 0

      asset_types = Asset.group(:asset_type).size
      status_distribution = Asset.group(:status).size
      condition_distribution = Asset.group(:condition).size
      department_distribution = Asset.group(:department).size

      overdue_maintenance = Asset.overdue_maintenance.size
      due_maintenance_soon = Asset.due_maintenance_soon.size
      warranty_expiring_soon = Asset.warranty_expiring_soon.size

      # Calculate average asset age safely (SQLite compatible)
      assets_with_dates = Asset.where.not(purchase_date: nil)
      if assets_with_dates.exists?
        # PostgreSQL: Calculate average age in years
        average_age = assets_with_dates.average("EXTRACT(YEAR FROM AGE(CURRENT_DATE, purchase_date))")
        average_age = average_age ? average_age.round(1) : 0.0
      else
        average_age = 0.0
      end

      render json: {
        overview: {
          total_assets: total_assets,
          assigned_assets: assigned_assets,
          available_assets: available_assets,
          maintenance_assets: maintenance_assets,
          utilization_rate: total_assets > 0 ? (assigned_assets.to_f / total_assets * 100).round(1) : 0
        },
        financial: {
          total_value: total_value,
          purchase_value: purchase_value,
          depreciation: purchase_value - total_value,
          average_asset_age: average_age
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

    # GET /api/assets/allocations
    def allocations
      @allocations = AssetAllocation.includes(:asset, :employee).active.recent

      render json: {
        allocations: @allocations.map { |allocation| format_allocation(allocation) },
        total_active_allocations: @allocations.size
      }
    end

    # GET /api/assets/maintenance
    def maintenance
      @maintenance_records = MaintenanceRecord.includes(:asset).recent.limit(20)
      @overdue_assets = Asset.overdue_maintenance.includes(:employee)
      @due_soon_assets = Asset.due_maintenance_soon.includes(:employee)

      render json: {
        recent_maintenance: @maintenance_records.map { |record| format_maintenance_record(record) },
        overdue_maintenance: @overdue_assets.map { |asset| format_asset(asset) },
        due_maintenance_soon: @due_soon_assets.map { |asset| format_asset(asset) },
        maintenance_stats: {
          total_maintenance_cost: MaintenanceRecord.sum(:cost) || 0,
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

    def send_png(binary, filename:)
      send_data binary,
                type: "image/png",
                disposition: "inline",
                filename: filename
    end

    def png_data_url(binary)
      "data:image/png;base64,#{Base64.strict_encode64(binary)}"
    end
  end
end
