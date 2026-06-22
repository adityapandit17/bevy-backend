# frozen_string_literal: true

module AssetApiFormatting
  extend ActiveSupport::Concern

  private

  def format_asset(asset)
    base_url = request.base_url
    label = AssetLabelService.new(asset)

    {
      id: asset.id,
      name: asset.name,
      asset_type: asset.asset_type,
      asset_tag: asset.asset_tag,
      scan_payload: label.scan_payload,
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
      label: label.label_metadata(base_url: base_url),
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
end
