class DigitalSignaturesController < ApplicationController
  before_action :set_digital_signature, only: [ :show, :update, :destroy ]

  # GET /digital_signatures
  def index
    @digital_signatures = DigitalSignature.includes(:policy_document, :employee)
                                          .order(created_at: :desc)

    # Filter by status if provided
    @digital_signatures = @digital_signatures.where(status: params[:status]) if params[:status].present?

    # Filter by policy_document_id if provided
    @digital_signatures = @digital_signatures.where(policy_document_id: params[:policy_document_id]) if params[:policy_document_id].present?

    # Filter by employee_id if provided
    @digital_signatures = @digital_signatures.where(employee_id: params[:employee_id]) if params[:employee_id].present?

    render json: @digital_signatures.map { |sig| format_digital_signature(sig) }
  end

  # GET /digital_signatures/:id
  def show
    render json: format_digital_signature(@digital_signature)
  end

  # POST /digital_signatures
  def create
    @digital_signature = DigitalSignature.new(digital_signature_params)

    if @digital_signature.save
      render json: format_digital_signature(@digital_signature), status: :created
    else
      render json: { errors: @digital_signature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /digital_signatures/:id
  def update
    if @digital_signature.update(digital_signature_params)
      render json: format_digital_signature(@digital_signature)
    else
      render json: { errors: @digital_signature.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /digital_signatures/:id
  def destroy
    @digital_signature.destroy
    head :no_content
  end

  # GET /digital_signatures/stats
  def stats
    total_signatures = DigitalSignature.count
    pending_signatures = DigitalSignature.pending.count
    signed_signatures = DigitalSignature.signed.count
    rejected_signatures = DigitalSignature.rejected.count

    render json: {
      total: total_signatures,
      pending: pending_signatures,
      signed: signed_signatures,
      rejected: rejected_signatures
    }
  end

  # POST /digital_signatures/:id/sign
  def sign
    @digital_signature = find_in_tenant(DigitalSignature, params[:id])

    # Capture device info from request
    device_info = extract_device_info(request)

    if @digital_signature.update(
      status: "signed",
      signed_date: Date.current,
      signature_type: "electronic",
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
    pending_signatures = DigitalSignature.pending.includes(:employee, :policy_document)

    # Get policy_document_ids if provided
    policy_document_ids = params[:policy_document_ids] || []

    if policy_document_ids.any?
      pending_signatures = pending_signatures.where(policy_document_id: policy_document_ids)
    end

    count = pending_signatures.count

    # TODO: Implement actual email sending logic here
    # For now, just return the count

    render json: {
      message: "Reminders sent to #{count} employee(s)",
      count: count
    }
  end

  private

  def set_digital_signature
    @digital_signature = find_in_tenant(DigitalSignature, params[:id])
  end

  def digital_signature_params
    params.require(:digital_signature).permit(
      :policy_document_id,
      :employee_id,
      :signed_date,
      :status,
      :signature_type,
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
      createdAt: sig.created_at.iso8601,
      updatedAt: sig.updated_at.iso8601
    }
  end

  def extract_device_info(request)
    user_agent = request.user_agent || ""

    # Simple device detection
    if user_agent.include?("Chrome")
      browser = "Chrome"
    elsif user_agent.include?("Firefox")
      browser = "Firefox"
    elsif user_agent.include?("Safari") && !user_agent.include?("Chrome")
      browser = "Safari"
    elsif user_agent.include?("Edge")
      browser = "Edge"
    else
      browser = "Unknown"
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
