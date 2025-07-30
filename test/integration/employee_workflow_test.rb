require "test_helper"

class EmployeeWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @department = departments(:one)
  end

  test "complete employee onboarding workflow" do
    # Step 1: Create a new employee
    employee_attributes = {
      first_name: "Jane",
      last_name: "Smith",
      email: "jane.smith@example.com",
      phone: "1234567890",
      department_id: @department.id,
      designation: "Software Engineer",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee_attributes }, as: :json
    assert_response :created
    
    employee_response = JSON.parse(@response.body)
    employee_id = employee_response["id"]
    assert_equal "Jane Smith", employee_response["name"]
    assert_equal "active", employee_response["status"]

    # Step 2: Create assets for the employee
    laptop_attributes = {
      name: "MacBook Pro",
      asset_type: "laptop",
      serial_number: "MBP123456789",
      brand: "Apple",
      model: "MacBook Pro 16-inch",
      purchase_date: Date.current,
      purchase_cost: 2500.00,
      current_value: 2500.00,
      status: "available",
      location: "Office A",
      department: "Engineering",
      condition: "excellent"
    }

    post assets_url, params: { asset: laptop_attributes }, as: :json
    assert_response :created
    
    laptop_response = JSON.parse(@response.body)
    laptop_id = laptop_response["asset"]["id"]
    assert_equal "available", laptop_response["asset"]["status"]

    # Step 3: Allocate laptop to employee
    patch asset_url(laptop_id), params: { asset: { employee_id: employee_id } }, as: :json
    assert_response :success
    
    laptop_updated = JSON.parse(@response.body)
    assert_equal "assigned", laptop_updated["asset"]["status"]
    assert_equal employee_id, laptop_updated["asset"]["assigned_to"]["id"]

    # Step 4: Create a leave request for the employee
    leave_attributes = {
      employee_id: employee_id,
      leave_type: "annual",
      start_date: Date.current + 1.month,
      end_date: Date.current + 1.month + 1.week,
      reason: "Summer vacation",
      status: "pending"
    }

    post leave_requests_url, params: { leave_request: leave_attributes }, as: :json
    assert_response :created
    
    leave_response = JSON.parse(@response.body)
    leave_id = leave_response["id"]
    assert_equal "pending", leave_response["status"]
    assert_equal 8, leave_response["days"]

    # Step 5: Approve the leave request
    patch leave_request_url(leave_id), params: { leave_request: { status: "approved" } }, as: :json
    assert_response :success
    
    leave_updated = JSON.parse(@response.body)
    assert_equal "approved", leave_updated["status"]

    # Step 6: Update employee information
    patch employee_url(employee_id), params: { employee: { designation: "Senior Software Engineer" } }, as: :json
    assert_response :success
    
    employee_updated = JSON.parse(@response.body)
    assert_equal "Senior Software Engineer", employee_updated["designation"]

    # Step 7: Verify all relationships are working
    get employee_url(employee_id), as: :json
    assert_response :success
    
    employee_details = JSON.parse(@response.body)
    assert_equal "Jane Smith", employee_details["name"]
    assert_equal "Senior Software Engineer", employee_details["designation"]

    # Step 8: Check asset allocation
    get asset_url(laptop_id), as: :json
    assert_response :success
    
    asset_details = JSON.parse(@response.body)
    assert_equal "assigned", asset_details["asset"]["status"]
    assert_equal "Jane Smith", asset_details["asset"]["assigned_to"]["name"]

    # Step 9: Check leave request details
    get leave_request_url(leave_id), as: :json
    assert_response :success
    
    leave_details = JSON.parse(@response.body)
    assert_equal "approved", leave_details["status"]
    assert_equal "Jane Smith", leave_details["employee_name"]

    # Step 10: Test employee statistics
    get employees_url, as: :json
    assert_response :success
    
    employees_list = JSON.parse(@response.body)
    assert employees_list.any? { |emp| emp["id"] == employee_id }
  end

  test "employee termination workflow" do
    # Step 1: Create an employee
    employee_attributes = {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "0987654321",
      department_id: @department.id,
      designation: "Developer",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee_attributes }, as: :json
    assert_response :created
    
    employee_response = JSON.parse(@response.body)
    employee_id = employee_response["id"]

    # Step 2: Allocate an asset to the employee
    asset_attributes = {
      name: "Dell Laptop",
      asset_type: "laptop",
      serial_number: "DELL123456789",
      brand: "Dell",
      model: "Latitude",
      purchase_date: Date.current,
      purchase_cost: 1500.00,
      current_value: 1500.00,
      status: "available",
      location: "Office B",
      department: "Engineering",
      condition: "good"
    }

    post assets_url, params: { asset: asset_attributes }, as: :json
    assert_response :created
    
    asset_response = JSON.parse(@response.body)
    asset_id = asset_response["asset"]["id"]

    # Allocate asset to employee
    patch asset_url(asset_id), params: { asset: { employee_id: employee_id } }, as: :json
    assert_response :success

    # Step 3: Terminate the employee
    delete employee_url(employee_id), as: :json
    assert_response :success

    # Step 4: Verify employee status is inactive
    get employee_url(employee_id), as: :json
    assert_response :success
    
    employee_terminated = JSON.parse(@response.body)
    assert_equal "inactive", employee_terminated["status"]

    # Step 5: Verify asset is no longer assigned
    get asset_url(asset_id), as: :json
    assert_response :success
    
    asset_unassigned = JSON.parse(@response.body)
    assert_equal "available", asset_unassigned["asset"]["status"]
    assert_nil asset_unassigned["asset"]["assigned_to"]
  end

  test "department management workflow" do
    # Step 1: Create a new department
    department_attributes = { name: "Quality Assurance" }
    
    post departments_url, params: { department: department_attributes }, as: :json
    assert_response :created
    
    department_response = JSON.parse(@response.body)
    department_id = department_response["id"]
    assert_equal "Quality Assurance", department_response["name"]

    # Step 2: Create employees in the new department
    employee1_attributes = {
      first_name: "Alice",
      last_name: "Johnson",
      email: "alice.johnson@example.com",
      phone: "1111111111",
      department_id: department_id,
      designation: "QA Engineer",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee1_attributes }, as: :json
    assert_response :created
    
    employee1_response = JSON.parse(@response.body)
    employee1_id = employee1_response["id"]

    employee2_attributes = {
      first_name: "Bob",
      last_name: "Wilson",
      email: "bob.wilson@example.com",
      phone: "2222222222",
      department_id: department_id,
      designation: "Senior QA Engineer",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee2_attributes }, as: :json
    assert_response :created
    
    employee2_response = JSON.parse(@response.body)
    employee2_id = employee2_response["id"]

    # Step 3: Update department name
    patch department_url(department_id), params: { department: { name: "Quality Assurance & Testing" } }, as: :json
    assert_response :success
    
    department_updated = JSON.parse(@response.body)
    assert_equal "Quality Assurance & Testing", department_updated["name"]

    # Step 4: Verify employees are in the updated department
    get employee_url(employee1_id), as: :json
    assert_response :success
    
    employee1_details = JSON.parse(@response.body)
    assert_equal department_id, employee1_details["department_id"]

    get employee_url(employee2_id), as: :json
    assert_response :success
    
    employee2_details = JSON.parse(@response.body)
    assert_equal department_id, employee2_details["department_id"]

    # Step 5: Delete department (should still work even with employees)
    delete department_url(department_id), as: :json
    assert_response :success
  end

  test "asset lifecycle workflow" do
    # Step 1: Create an asset
    asset_attributes = {
      name: "HP Printer",
      asset_type: "printer",
      serial_number: "HP123456789",
      brand: "HP",
      model: "LaserJet Pro",
      purchase_date: Date.current,
      purchase_cost: 800.00,
      current_value: 800.00,
      status: "available",
      location: "Office C",
      department: "IT",
      condition: "good"
    }

    post assets_url, params: { asset: asset_attributes }, as: :json
    assert_response :created
    
    asset_response = JSON.parse(@response.body)
    asset_id = asset_response["asset"]["id"]
    assert_equal "available", asset_response["asset"]["status"]

    # Step 2: Create an employee to assign the asset to
    employee_attributes = {
      first_name: "Charlie",
      last_name: "Brown",
      email: "charlie.brown@example.com",
      phone: "3333333333",
      department_id: @department.id,
      designation: "IT Support",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee_attributes }, as: :json
    assert_response :created
    
    employee_response = JSON.parse(@response.body)
    employee_id = employee_response["id"]

    # Step 3: Assign asset to employee
    patch asset_url(asset_id), params: { asset: { employee_id: employee_id } }, as: :json
    assert_response :success
    
    asset_assigned = JSON.parse(@response.body)
    assert_equal "assigned", asset_assigned["asset"]["status"]

    # Step 4: Put asset under maintenance
    patch asset_url(asset_id), params: { asset: { status: "maintenance" } }, as: :json
    assert_response :success
    
    asset_maintenance = JSON.parse(@response.body)
    assert_equal "maintenance", asset_maintenance["asset"]["status"]

    # Step 5: Return asset to available status
    patch asset_url(asset_id), params: { asset: { status: "available", employee_id: nil } }, as: :json
    assert_response :success
    
    asset_available = JSON.parse(@response.body)
    assert_equal "available", asset_available["asset"]["status"]
    assert_nil asset_available["asset"]["assigned_to"]

    # Step 6: Retire the asset
    patch asset_url(asset_id), params: { asset: { status: "retired" } }, as: :json
    assert_response :success
    
    asset_retired = JSON.parse(@response.body)
    assert_equal "retired", asset_retired["asset"]["status"]

    # Step 7: Delete the asset
    delete asset_url(asset_id), as: :json
    assert_response :success
  end

  test "leave request approval workflow" do
    # Step 1: Create an employee
    employee_attributes = {
      first_name: "Diana",
      last_name: "Prince",
      email: "diana.prince@example.com",
      phone: "4444444444",
      department_id: @department.id,
      designation: "Project Manager",
      date_of_joining: Date.current,
      status: "active"
    }

    post employees_url, params: { employee: employee_attributes }, as: :json
    assert_response :created
    
    employee_response = JSON.parse(@response.body)
    employee_id = employee_response["id"]

    # Step 2: Create multiple leave requests
    leave1_attributes = {
      employee_id: employee_id,
      leave_type: "annual",
      start_date: Date.current + 1.month,
      end_date: Date.current + 1.month + 1.week,
      reason: "Summer vacation",
      status: "pending"
    }

    post leave_requests_url, params: { leave_request: leave1_attributes }, as: :json
    assert_response :created
    
    leave1_response = JSON.parse(@response.body)
    leave1_id = leave1_response["id"]

    leave2_attributes = {
      employee_id: employee_id,
      leave_type: "sick",
      start_date: Date.current + 2.weeks,
      end_date: Date.current + 2.weeks + 2.days,
      reason: "Medical appointment",
      status: "pending"
    }

    post leave_requests_url, params: { leave_request: leave2_attributes }, as: :json
    assert_response :created
    
    leave2_response = JSON.parse(@response.body)
    leave2_id = leave2_response["id"]

    # Step 3: Approve first leave request
    patch leave_request_url(leave1_id), params: { leave_request: { status: "approved" } }, as: :json
    assert_response :success
    
    leave1_approved = JSON.parse(@response.body)
    assert_equal "approved", leave1_approved["status"]

    # Step 4: Reject second leave request
    patch leave_request_url(leave2_id), params: { leave_request: { status: "rejected" } }, as: :json
    assert_response :success
    
    leave2_rejected = JSON.parse(@response.body)
    assert_equal "rejected", leave2_rejected["status"]

    # Step 5: Create a third leave request and cancel it
    leave3_attributes = {
      employee_id: employee_id,
      leave_type: "personal",
      start_date: Date.current + 3.weeks,
      end_date: Date.current + 3.weeks + 1.day,
      reason: "Personal emergency",
      status: "pending"
    }

    post leave_requests_url, params: { leave_request: leave3_attributes }, as: :json
    assert_response :created
    
    leave3_response = JSON.parse(@response.body)
    leave3_id = leave3_response["id"]

    patch leave_request_url(leave3_id), params: { leave_request: { status: "cancelled" } }, as: :json
    assert_response :success
    
    leave3_cancelled = JSON.parse(@response.body)
    assert_equal "cancelled", leave3_cancelled["status"]

    # Step 6: Verify all leave requests have correct statuses
    get leave_requests_url, as: :json
    assert_response :success
    
    leave_requests = JSON.parse(@response.body)
    approved_requests = leave_requests.select { |lr| lr["status"] == "approved" }
    rejected_requests = leave_requests.select { |lr| lr["status"] == "rejected" }
    cancelled_requests = leave_requests.select { |lr| lr["status"] == "cancelled" }

    assert_equal 1, approved_requests.length
    assert_equal 1, rejected_requests.length
    assert_equal 1, cancelled_requests.length
  end

  test "concurrent operations workflow" do
    # Test that multiple operations can happen concurrently without conflicts
    
    # Create multiple employees simultaneously
    threads = []
    employee_ids = []
    
    5.times do |i|
      threads << Thread.new do
        employee_attributes = {
          first_name: "Concurrent#{i}",
          last_name: "Employee#{i}",
          email: "concurrent#{i}@example.com",
          phone: "#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}",
          department_id: @department.id,
          designation: "Developer",
          date_of_joining: Date.current,
          status: "active"
        }
        
        response = post employees_url, params: { employee: employee_attributes }, as: :json
        if response == 201
          employee_ids << JSON.parse(@response.body)["id"]
        end
      end
    end
    
    threads.each(&:join)
    
    # Verify all employees were created
    assert_equal 5, employee_ids.length
    
    # Create assets for each employee
    asset_threads = []
    
    employee_ids.each_with_index do |employee_id, i|
      asset_threads << Thread.new do
        asset_attributes = {
          name: "Asset #{i}",
          asset_type: "laptop",
          serial_number: "ASSET#{i}123456789",
          brand: "Brand #{i}",
          model: "Model #{i}",
          purchase_date: Date.current,
          purchase_cost: 1000.00 + i * 100,
          current_value: 1000.00 + i * 100,
          status: "available",
          location: "Office #{i}",
          department: "Engineering",
          condition: "good"
        }
        
        post assets_url, params: { asset: asset_attributes }, as: :json
        if @response.status == 201
          asset_id = JSON.parse(@response.body)["asset"]["id"]
          # Assign asset to employee
          patch asset_url(asset_id), params: { asset: { employee_id: employee_id } }, as: :json
        end
      end
    end
    
    asset_threads.each(&:join)
    
    # Verify all operations completed successfully
    get employees_url, as: :json
    assert_response :success
    
    employees = JSON.parse(@response.body)
    assert employees.length >= 5
    
    get assets_url, as: :json
    assert_response :success
    
    assets = JSON.parse(@response.body)
    assert assets["total_count"] >= 5
  end
end 