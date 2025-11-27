class PolicyDocumentsController < ApplicationController
  # JwtAuthenticatable concern handles authentication via should_authenticate? method
  before_action :set_policy_document, only: [:show, :update, :destroy, :download]

  # GET /policy_documents
  # All authenticated users can view
  def index
    @policy_documents = PolicyDocument.order(last_updated: :desc)
    render json: @policy_documents.map { |doc| format_policy_document(doc) }
  end

  # GET /policy_documents/:id
  # All authenticated users can view
  def show
    render json: format_policy_document(@policy_document)
  end

  # GET /policy_documents/:id/download
  # All authenticated users can download
  def download
    # Force authentication for all requests (JSON or file downloads)
    token = JwtService.extract_token(request.headers["Authorization"])
    
    if token.blank?
      Rails.logger.error "JWT Authentication failed: No token provided for policy_documents#download"
      render json: { error: "Authorization token is required" }, status: :unauthorized
      return
    end

    user = JwtService.verify_token(token)

    if user
      user.roles.load unless user.association(:roles).loaded?
      @current_user = user
      Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
    else
      Rails.logger.error "JWT Authentication failed: Invalid or expired token for policy_documents#download"
      render json: { error: "Invalid or expired token" }, status: :unauthorized
      return
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    @policy_document.increment_downloads!
    
    file_path = Rails.root.join("storage", "uploads", @policy_document.file_path)
    
    if File.exist?(file_path)
      # Set proper MIME type based on file extension
      mime_type = case File.extname(@policy_document.file_path).downcase
      when ".pdf"
        "application/pdf"
      when ".doc"
        "application/msword"
      when ".docx"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      else
        "application/octet-stream"
      end

      send_file file_path,
                type: mime_type,
                disposition: "attachment",
                filename: @policy_document.title
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end

  # POST /policy_documents
  # Only Super Admin and HR Manager can create
  def create
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])
      
      if token.blank?
        Rails.logger.error "JWT Authentication failed: No token provided for policy_documents#create"
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)

      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
        Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
      else
        Rails.logger.error "JWT Authentication failed: Invalid or expired token for policy_documents#create"
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end
    
    # current_user should be set by authentication above
    Rails.logger.info "Create action - @current_user: #{@current_user&.id}, current_user method: #{current_user&.id}"
    
    unless current_user
      Rails.logger.error "No current_user in create action - @current_user: #{@current_user.inspect}"
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end
    
    # Check permissions
    unless can_edit_policy_documents?
      render json: { error: "Insufficient permissions. Only Super Admin and HR Manager can create policy documents." }, status: :forbidden
      return
    end

    @policy_document = PolicyDocument.new(policy_document_params)
    @policy_document.uploaded_by = current_user.id
    @policy_document.last_updated = Date.current
    @policy_document.downloads = 0

    if @policy_document.save
      render json: format_policy_document(@policy_document), status: :created
    else
      render json: { errors: @policy_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /policy_documents/:id
  # Only Super Admin and HR Manager can update
  def update
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])
      
      if token.blank?
        Rails.logger.error "JWT Authentication failed: No token provided for policy_documents#update"
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)

      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
        Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
      else
        Rails.logger.error "JWT Authentication failed: Invalid or expired token for policy_documents#update"
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    unless can_edit_policy_documents?
      render json: { error: "Insufficient permissions. Only Super Admin and HR Manager can edit policy documents." }, status: :forbidden
      return
    end

    if @policy_document.update(policy_document_params)
      render json: format_policy_document(@policy_document)
    else
      render json: { errors: @policy_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /policy_documents/:id
  # Only Super Admin and HR Manager can delete
  def destroy
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])
      
      if token.blank?
        Rails.logger.error "JWT Authentication failed: No token provided for policy_documents#destroy"
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)

      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
        Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
      else
        Rails.logger.error "JWT Authentication failed: Invalid or expired token for policy_documents#destroy"
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    unless can_edit_policy_documents?
      render json: { error: "Insufficient permissions. Only Super Admin and HR Manager can delete policy documents." }, status: :forbidden
      return
    end

    @policy_document.destroy
    head :no_content
  end

  private

  def set_policy_document
    @policy_document = PolicyDocument.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Policy document not found" }, status: :not_found
  end

  def policy_document_params
    params.require(:policy_document).permit(
      :title,
      :category,
      :version,
      :file_path,
      :file_size,
      :expiry_date,
      :status,
      :requires_signature
    )
  end

  def can_edit_policy_documents?
    return false unless current_user
    
    # Use direct database query to check roles (most reliable)
    # This works even if associations aren't loaded
    user_id = current_user.id
    is_super_admin = User.joins(:roles).where(id: user_id, roles: { name: "Super Admin" }).exists?
    is_hr_manager = User.joins(:roles).where(id: user_id, roles: { name: "HR Manager" }).exists?
    
    Rails.logger.debug "Permission check - User: #{user_id}, Super Admin: #{is_super_admin}, HR Manager: #{is_hr_manager}"
    
    is_super_admin || is_hr_manager
  end

  def format_policy_document(doc)
    {
      id: doc.id,
      title: doc.title,
      category: doc.category,
      version: doc.version,
      lastUpdated: doc.formatted_last_updated,
      expiryDate: doc.formatted_expiry_date,
      status: doc.status,
      downloads: doc.downloads,
      size: doc.file_size_formatted,
      type: File.extname(doc.file_path).downcase[1..-1] || "pdf",
      requiresSignature: doc.requires_signature,
      filePath: doc.file_path,
      createdAt: doc.created_at,
      updatedAt: doc.updated_at
    }
  end
end

