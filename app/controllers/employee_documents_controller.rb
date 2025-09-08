class EmployeeDocumentsController < ApplicationController
  before_action :set_employee_document, only: [:show, :update, :destroy]

  def index
    @employee_documents = EmployeeDocument.all
    render json: @employee_documents
  end

  def show
    render json: @employee_document
  end

  def create
    @employee_document = EmployeeDocument.new(employee_document_params)
    if @employee_document.save
      render json: @employee_document, status: :created
    else
      render json: { errors: @employee_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @employee_document.update(employee_document_params)
      render json: @employee_document
    else
      render json: { errors: @employee_document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
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
    params.require(:employee_document).permit(:employee_id, :name, :document_type, :upload_date, :expiry_date, :status, :file_size, :uploaded_by)
  end
end
