class EmployeeDocumentsController < ApplicationController
  before_action :set_employee_document, only: [ :show, :update, :destroy ]

  def index
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])

      if token.blank?
        Rails.logger.error "JWT Authentication failed: No token provided for employee_documents#index"
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)

      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
        Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
      else
        Rails.logger.error "JWT Authentication failed: Invalid or expired token for employee_documents#index"
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    @employee_documents = EmployeeDocument.includes(:employee).all
    render json: @employee_documents.map { |doc| format_employee_document(doc) }
  end

  def show
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])

      if token.blank?
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)
      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
      else
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    render json: format_employee_document(@employee_document)
  end

  def create
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])

      if token.blank?
        Rails.logger.error "JWT Authentication failed: No token provided for employee_documents#create"
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)

      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
        Rails.logger.info "JWT Authentication successful - User: #{user.id}, Email: #{user.email}"
      else
        Rails.logger.error "JWT Authentication failed: Invalid or expired token for employee_documents#create"
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    @employee_document = EmployeeDocument.new(employee_document_params)
    @employee_document.uploaded_by = current_user.name || "System"

    if @employee_document.save
      render json: format_employee_document(@employee_document), status: :created
    else
      render json: { errors: @employee_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])

      if token.blank?
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)
      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
      else
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    if @employee_document.update(employee_document_params)
      render json: format_employee_document(@employee_document)
    else
      render json: { errors: @employee_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # Force authentication for JSON requests
    if json_request? && !login_endpoint?
      token = JwtService.extract_token(request.headers["Authorization"])

      if token.blank?
        render json: { error: "Authorization token is required" }, status: :unauthorized
        return
      end

      user = JwtService.verify_token(token)
      if user
        user.roles.load unless user.association(:roles).loaded?
        @current_user = user
      else
        render json: { error: "Invalid or expired token" }, status: :unauthorized
        return
      end
    end

    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    @employee_document.destroy
    head :no_content
  end

  private

  def set_employee_document
    @employee_document = EmployeeDocument.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee document not found" }, status: :not_found
  end

  def employee_document_params
    params.require(:employee_document).permit(:employee_id, :name, :document_type, :upload_date, :expiry_date, :status, :file_size, :uploaded_by, :file_path)
  end

  def format_employee_document(doc)
    {
      id: doc.id,
      employee_id: doc.employee_id,
      employee_name: doc.employee&.name || (doc.employee&.first_name ? "#{doc.employee.first_name} #{doc.employee.last_name}" : nil),
      name: doc.name,
      document_type: doc.document_type,
      upload_date: doc.upload_date&.iso8601,
      expiry_date: doc.expiry_date&.iso8601,
      status: doc.status,
      file_size: doc.file_size,
      uploaded_by: doc.uploaded_by,
      file_path: doc.file_path,
      created_at: doc.created_at,
      updated_at: doc.updated_at
    }
  end

  def json_request?
    request.format.json? || request.headers["Accept"]&.include?("application/json")
  end

  def login_endpoint?
    request.path == "/api/v1/auth/login"
  end
end
