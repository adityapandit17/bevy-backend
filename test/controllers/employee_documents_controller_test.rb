require "test_helper"

class EmployeeDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @employee = employees(:one)
    @employee_document = employee_documents(:one)
    @valid_attributes = {
      employee_id: @employee.id,
      name: "Employment Contract",
      document_type: "contract",
      upload_date: Date.current,
      expiry_date: Date.current + 1.year,
      status: "active",
      file_size: "2.5MB",
      uploaded_by: "HR Manager"
    }
  end

  test "should get index" do
    get employee_documents_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
  end

  test "should show employee document" do
    get employee_document_url(@employee_document), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @employee_document.id, json_response["id"]
  end

  test "should create employee document" do
    assert_difference('EmployeeDocument.count') do
      post employee_documents_url, params: { employee_document: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
    assert_equal @valid_attributes[:document_type], json_response["document_type"]
  end

  test "should not create employee document with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(employee_id: 99999)
    
    assert_no_difference('EmployeeDocument.count') do
      post employee_documents_url, params: { employee_document: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Employee must exist"
  end

  test "should update employee document" do
    patch employee_document_url(@employee_document), params: { 
      employee_document: { name: "Updated Document Name", expiry_date: Date.current - 1.day } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "expired", json_response["status"]
    assert_equal "Updated Document Name", json_response["name"]
  end

  test "should not update employee document with invalid attributes" do
    patch employee_document_url(@employee_document), params: { 
      employee_document: { document_type: "invalid_type" } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Document type is not included in the list"
  end

  test "should destroy employee document" do
    assert_difference('EmployeeDocument.count', -1) do
      delete employee_document_url(@employee_document), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 for non-existent employee document" do
    get employee_document_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent employee document" do
    patch employee_document_url(99999), params: { 
      employee_document: { status: "expired" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent employee document" do
    delete employee_document_url(99999), as: :json
    assert_response :not_found
  end

  test "should handle employee document with all required fields" do
    get employee_document_url(@employee_document), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id employee_id name document_type upload_date status created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle employee document with missing optional fields" do
    minimal_attributes = {
      employee_id: @employee.id,
      name: "Minimal Document",
      document_type: "contract",
      upload_date: Date.current,
      status: "active",
      file_size: "1MB",
      uploaded_by: "HR"
    }
    
    post employee_documents_url, params: { employee_document: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:name], json_response["name"]
    assert_equal minimal_attributes[:document_type], json_response["document_type"]
    # Optional fields should be null
    assert_nil json_response["expiry_date"]
    assert_nil json_response["description"]
  end
end
