require "test_helper"

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @department = departments(:one)
    @employee = employees(:one)
    @valid_attributes = {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "1234567890",
      department_id: @department.id,
      designation: "Software Engineer",
      date_of_joining: Date.current,
      status: "active"
    }
  end

  test "should get index" do
    get employees_url
    assert_response :success
  end

  test "should get index as json" do
    get employees_url, as: :json
    assert_response :success
    assert_equal "application/json", @response.media_type
  end

  test "should create employee with valid parameters" do
    unique_attributes = @valid_attributes.merge(email: "unique.employee@example.com")
    assert_difference("Employee.count") do
      post employees_url, params: { employee: unique_attributes }, as: :json
    end

    assert_response :created
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_equal unique_attributes[:first_name], json_response["first_name"]
    assert_equal unique_attributes[:last_name], json_response["last_name"]
    assert_equal unique_attributes[:email], json_response["email"]
  end

  test "should not create employee with invalid parameters" do
    invalid_attributes = @valid_attributes.merge(email: nil)

    assert_no_difference("Employee.count") do
      post employees_url, params: { employee: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Email can't be blank"
  end

  test "should not create employee with duplicate email" do
    # First create an employee with unique email
    unique_attributes = @valid_attributes.merge(email: "unique@example.com")
    post employees_url, params: { employee: unique_attributes }, as: :json
    assert_response :created

    # Try to create another with same email
    assert_no_difference("Employee.count") do
      post employees_url, params: { employee: unique_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Email has already been taken"
  end

  test "should not create employee with invalid email format" do
    invalid_attributes = @valid_attributes.merge(email: "invalid-email")

    assert_no_difference("Employee.count") do
      post employees_url, params: { employee: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Email is invalid"
  end

  test "should not create employee without required fields" do
    required_fields = [ :first_name, :last_name, :email, :phone, :designation, :date_of_joining, :status ]

    required_fields.each do |field|
      invalid_attributes = @valid_attributes.dup
      invalid_attributes[field] = nil

      assert_no_difference("Employee.count") do
        post employees_url, params: { employee: invalid_attributes }, as: :json
      end

      assert_response :unprocessable_entity
      json_response = JSON.parse(@response.body)
      assert_includes json_response["errors"], "#{field.to_s.humanize} can't be blank"
    end
  end

  test "should update employee with valid parameters" do
    patch employee_url(@employee), params: { employee: { first_name: "Jane" } }, as: :json
    assert_response :success

    @employee.reload
    assert_equal "Jane", @employee.first_name
  end

  test "should not update employee with invalid parameters" do
    patch employee_url(@employee), params: { employee: { email: nil } }, as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Email can't be blank"
  end

  test "should not update employee with duplicate email" do
    # Create another employee first
    other_employee = Employee.create!(@valid_attributes.merge(email: "other@example.com"))

    # Try to update first employee with second employee's email
    patch employee_url(@employee), params: { employee: { email: other_employee.email } }, as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], "Email has already been taken"
  end

  test "should destroy employee by setting status to inactive" do
    assert_not_equal "inactive", @employee.status

    delete employee_url(@employee), as: :json
    assert_response :success

    @employee.reload
    assert_equal "inactive", @employee.status
  end

  test "should handle destroy with invalid employee" do
    delete employee_url(999999), as: :json
    assert_response :not_found
  end

  test "should handle update with invalid employee" do
    patch employee_url(999999), params: { employee: { first_name: "Jane" } }, as: :json
    assert_response :not_found
  end

  test "should handle show with invalid employee" do
    get employee_url(999999), as: :json
    assert_response :not_found
  end

  test "should handle create with missing employee parameter" do
    post employees_url, params: {}, as: :json
    assert_response :bad_request
  end

  test "should handle update with missing employee parameter" do
    patch employee_url(@employee), params: {}, as: :json
    assert_response :bad_request
  end

  test "should create employee with all valid statuses" do
    valid_statuses = %w[active inactive terminated probation]

    valid_statuses.each do |status|
      attributes = @valid_attributes.merge(
        email: "#{status}@example.com",
        status: status
      )

      assert_difference("Employee.count") do
        post employees_url, params: { employee: attributes }, as: :json
      end

      assert_response :created
      json_response = JSON.parse(@response.body)
      assert_equal status, json_response["status"]
    end
  end

  test "should handle large number of employees in index" do
    # Create multiple employees
    10.times do |i|
      Employee.create!(@valid_attributes.merge(
        email: "employee#{i}@example.com",
        first_name: "Employee#{i}"
      ))
    end

    get employees_url, as: :json
    assert_response :success

    json_response = JSON.parse(@response.body)
    # Index returns paginated {data: [...], pagination: {...}}
    employees_data = json_response.is_a?(Array) ? json_response : json_response["data"]
    assert employees_data.length >= 10
  end

  test "should handle special characters in employee data" do
    special_attributes = @valid_attributes.merge(
      first_name: "José María",
      last_name: "O'Connor-Smith",
      email: "jose.maria@example.com"
    )

    post employees_url, params: { employee: special_attributes }, as: :json
    assert_response :created

    json_response = JSON.parse(@response.body)
    assert_equal "José María", json_response["first_name"]
    assert_equal "O'Connor-Smith", json_response["last_name"]
  end

  test "should handle long text fields" do
    long_attributes = @valid_attributes.merge(
      first_name: "A" * 255,
      last_name: "B" * 255,
      email: "long@example.com"
    )

    post employees_url, params: { employee: long_attributes }, as: :json
    assert_response :created
  end

  test "should handle phone number formats" do
    phone_formats = [
      "1234567890",
      "+1-234-567-8900",
      "(123) 456-7890",
      "123.456.7890"
    ]

    phone_formats.each_with_index do |phone, index|
      attributes = @valid_attributes.dup.merge(
        email: "phone#{index}_#{phone.gsub(/\D/, '')}@example.com",
        phone: phone
      )

      post employees_url, params: { employee: attributes }, as: :json
      assert_response :created
    end
  end

  test "should handle date formats" do
    date_formats = [
      Date.current,
      Date.current - 1.year,
      Date.current + 1.month
    ]

    date_formats.each do |date|
      attributes = @valid_attributes.merge(
        email: "date#{date.to_s.gsub('-', '')}@example.com",
        date_of_joining: date
      )

      post employees_url, params: { employee: attributes }, as: :json
      assert_response :created
    end
  end

  test "should handle concurrent employee creation" do
    # This test simulates concurrent requests
    threads = []
    results = []

    5.times do |i|
      threads << Thread.new do
        attributes = @valid_attributes.merge(
          email: "concurrent#{i}@example.com"
        )
        response = post employees_url, params: { employee: attributes }, as: :json
        results << response
      end
    end

    threads.each(&:join)

    # All should succeed
    results.each do |result|
      assert_equal 201, result
    end
  end

  test "should handle empty JSON body" do
    post employees_url,
         params: "{}",
         headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end
end
