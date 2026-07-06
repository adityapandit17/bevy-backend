# frozen_string_literal: true

class DigitalSignaturesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_digital_signature, only: [ :show, :update, :destroy, :sign ]

  # GET /digital_signatures
  def index
    @digital_signatures = scoped_signatures.includes(:policy_document, :employee).order(created_at: :desc)
    @digital_signatures = @digital_signatures.where(status: params[:status]) if params[:status].present?
    @digital_signatures = @digital_signatures.where(policy_document_id: params[:policy_document_id]) if params[:policy_document_id].present?
    @digital_signatures = @digital_signatures.where(employee_id: params[:employee_id]) if params[:employee_id].present?

    render json: @digital_signatures.map { |sig| format_digital_signature(sig) }
  end

  # GET /digital_signatures/my_pending
  def my_pending
    employee = current_user&.employee
    return render json: [] unless employee

    signatures = DigitalSignature.pending
                                 .where(employee_id: employee.id)
                                 .includes(:policy_document)
                                 .order(created_at: :desc)

    render json: signatures.map { |sig| format_digital_signature(sig) }
  end

  # GET /digital_signatures/:id
  def show
    render json: format_digital_signature(@digital_signature)
  end

  # POST /digital_signatures
  def create
    unless can_manage_signatures?
      return render json: { error: "Insufficient permissions" }, status: :forbidden
    end

    @digital_signature = DigitalSignature.new(digital_signature_params)
    @digital_signature.status ||= "pending"
    @digital_signature.signature_type ||= "pending"

    if @digital_signature.save
      render json: format_digital_signature(@digital_signature), status: :created
    else
      render json: { errors: @digital_signature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /digital_signatures/:id
  def update
    unless can_manage_signatures?
      return render json: { error: "Insufficient permissions" }, status: :forbidden
    end

    if @digital_signature.update(digital_signature_params)
      render json: format_digital_signature(@digital_signature)
    else
      render json: { errors: @digital_signature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /digital_signatures/:id
  def destroy
    unless can_manage_signatures?
      return render json: { error: "Insufficient permissions" }, status: :forbidden
    end

    @digital_signature.destroy
    head :no_content
  end

  # GET /digital_signatures/stats
  def stats
    render json: {
      total: scoped_signatures.count,
      pending: scoped_signatures.pending.count,
      signed: scoped_signatures.signed.count,
      rejected: scoped_signatures.rejected.count
    }
  end

  # POST /digital_signatures/:id/sign
  def sign
    unless can_sign_signature?(@digital_signature)
      return render json: { error: "You can only sign your own pending documents" }, status: :forbidden
    end

    unless @digital_signature.pending?
      return render json: { error: "This document has already been signed" }, status: :unprocessable_entity
    end

    signature_image = params[:signature_image].presence || params.dig(:digital_signature, :signature_image)
    if signature_image.blank?
      return render json: { error: "Signature image is required" }, status: :unprocessable_entity
    end

    device_info = extract_device_info(request)

    if @digital_signature.update(
      status: "signed",
      signed_date: Date.current,
      signature_type: "electronic",
      signature_image: signature_image,
      ip_address: request.remote_ip,
      device_info: device_info,
      user_agent: request.user_agent
    )
      render json: format_digital_signature(@digital_signature)
    else
      render json: { errors: @digital_signature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /digital_signatures/send_reminders
  def send_reminders
    unless can_manage_signatures?
      return render json: { error: "Insufficient permissions" }, status: :forbidden
    end

    pending_signatures = DigitalSignature.pending.includes(:employee, :policy_document)
    policy_document_ids = Array(params[:policy_document_ids]).reject(&:blank?)
    pending_signatures = pending_signatures.where(policy_document_id: policy_document_ids) if policy_document_ids.any?

    count = pending_signatures.count

    render json: {
      message: "Reminders queued for #{count} employee(s)",
      count: count
    }
  end

  private

  def scoped_signatures
    if can_manage_signatures?
      DigitalSignature.all
    elsif current_user&.employee_id
      DigitalSignature.where(employee_id: current_user.employee_id)
    else
      DigitalSignature.none
    end
  end

  def set_digital_signature
    @digital_signature = scoped_signatures.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Digital signature not found" }, status: :not_found
  end

  def can_manage_signatures?
    return false unless current_user

    current_user.has_role?("Super Admin") ||
      current_user.has_role?("HR Manager") ||
      current_user.has_permission?("policy_documents", "update")
  end

  def can_sign_signature?(signature)
    current_user&.employee_id.present? &&
      signature.employee_id == current_user.employee_id
  end

  def digital_signature_params
    params.require(:digital_signature).permit(
      :policy_document_id,
      :employee_id,
      :signed_date,
      :status,
      :signature_type,
      :signature_image,
      :ip_address,
      :device_info,
      :user_agent
    )
  end

  def format_digital_signature(sig)
    {
      id: sig.id,
      documentTitle: sig.document_title,
      employeeName: sig.employee_name,
      employeeId: sig.employee_id,
      policyDocumentId: sig.policy_document_id,
      signedDate: sig.signed_date&.iso8601,
      status: sig.status,
      signatureType: sig.signature_type || (sig.status == "pending" ? "pending" : "electronic"),
      deviceInfo: sig.device_info_display,
      ipAddress: sig.ip_address,
      hasSignatureImage: sig.has_signature_image?,
      signatureImage: sig.signature_image,
      createdAt: sig.created_at.iso8601,
      updatedAt: sig.updated_at.iso8601
    }
  end

  def extract_device_info(request)
    user_agent = request.user_agent || ""

    browser = if user_agent.include?("Chrome")
      "Chrome"
    elsif user_agent.include?("Firefox")
      "Firefox"
    elsif user_agent.include?("Safari") && !user_agent.include?("Chrome")
      "Safari"
    elsif user_agent.include?("Edge")
      "Edge"
    else
      "Unknown"
    end

    os = if user_agent.include?("Windows")
      "Windows"
    elsif user_agent.include?("Mac")
      "Mac"
    elsif user_agent.include?("Linux")
      "Linux"
    elsif user_agent.include?("Android")
      "Android"
    elsif user_agent.include?("iOS")
      "iOS"
    else
      "Unknown"
    end

    "#{browser} on #{os}"
  end
end
