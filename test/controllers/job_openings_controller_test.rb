require "test_helper"

class JobOpeningsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @department = departments(:one)
    @job_opening = job_openings(:one)
    @valid_attributes = {
      title: "Senior Software Engineer",
      department_id: @department.id,
      description: "We are looking for an experienced software engineer to join our team and help build amazing products.",
      requirements: "5+ years of experience in Ruby on Rails, JavaScript, and React",
      status: "open",
      location: "San Francisco, CA",
      job_type: "full-time",
      vacancies: 2,
      salary_min: 80000,
      salary_max: 120000,
      experience: "5-8 years",
      skills: "Ruby, Rails, JavaScript, React, PostgreSQL",
      posted: Date.current,
      applications: 0
    }
  end

  test "should get index" do
    get job_openings_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    assert_not_empty json_response
  end

  test "should show job opening" do
    get job_opening_url(@job_opening), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @job_opening.id, json_response["id"]
    assert_equal @job_opening.title, json_response["title"]
    assert_equal @job_opening.department_id, json_response["department_id"]
  end

  test "should create job opening" do
    assert_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:title], json_response["title"]
    assert_equal @valid_attributes[:department_id], json_response["department_id"]
    assert_equal @valid_attributes[:status], json_response["status"]
  end

  test "should create job opening with minimal attributes" do
    minimal_attributes = {
      title: "Minimal Job",
      department_id: @department.id,
      description: "A minimal job description that meets the minimum length requirement.",
      requirements: "Basic requirements",
      status: "open",
      location: "Remote",
      job_type: "full-time",
      vacancies: 1,
      experience: "1-3 years",
      skills: "JavaScript",
      posted: Date.current
    }
    
    assert_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: minimal_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:title], json_response["title"]
    assert_equal minimal_attributes[:department_id], json_response["department_id"]
  end

  test "should not create job opening with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(title: "Short")
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Title is too short (minimum is 5 characters)"
  end

  test "should not create job opening with invalid department" do
    invalid_attributes = @valid_attributes.merge(department_id: 99999)
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Department must exist"
  end

  test "should not create job opening with invalid status" do
    invalid_attributes = @valid_attributes.merge(status: "invalid_status")
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Status is not included in the list"
  end

  test "should not create job opening with invalid job type" do
    invalid_attributes = @valid_attributes.merge(job_type: "invalid_type")
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Job type is not included in the list"
  end

  test "should not create job opening with invalid salary range" do
    invalid_attributes = @valid_attributes.merge(salary_min: 120000, salary_max: 80000)
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Salary max must be greater than minimum salary"
  end

  test "should not create job opening with invalid vacancies" do
    invalid_attributes = @valid_attributes.merge(vacancies: 0)
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Vacancies must be greater than 0"
  end

  test "should update job opening" do
    patch job_opening_url(@job_opening), params: { 
      job_opening: { 
        title: "Updated Title", 
        status: "closed",
        description: "Updated description that meets the minimum length requirement.",
        requirements: "Updated requirements",
        location: "Updated Location",
        job_type: "full-time",
        vacancies: 1,
        experience: "Updated experience",
        skills: "Updated skills",
        posted: Date.current
      } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Updated Title", json_response["title"]
    assert_equal "closed", json_response["status"]
  end

  test "should not update job opening with invalid attributes" do
    patch job_opening_url(@job_opening), params: { 
      job_opening: { 
        title: "Short",
        description: "Updated description that meets the minimum length requirement.",
        requirements: "Updated requirements",
        location: "Updated Location",
        job_type: "full-time",
        vacancies: 1,
        experience: "Updated experience",
        skills: "Updated skills",
        posted: Date.current
      } 
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Title is too short (minimum is 5 characters)"
  end

  test "should destroy job opening by setting status to inactive" do
    patch job_opening_url(@job_opening), params: { 
      job_opening: { 
        status: "closed",
        description: "Updated description that meets the minimum length requirement.",
        requirements: "Updated requirements",
        location: "Updated Location",
        job_type: "full-time",
        vacancies: 1,
        experience: "Updated experience",
        skills: "Updated skills",
        posted: Date.current
      } 
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "closed", json_response["status"]
  end

  test "should return 404 for non-existent job opening" do
    get job_opening_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent job opening" do
    patch job_opening_url(99999), params: { 
      job_opening: { title: "Updated Title" } 
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent job opening" do
    patch job_opening_url(99999), params: { 
      job_opening: { status: "Inactive" } 
    }, as: :json
    assert_response :not_found
  end

  test "should handle job opening with all valid statuses" do
    valid_statuses = %w[open closed draft filled]
    
    valid_statuses.each do |status|
      attributes = @valid_attributes.merge(status: status)
      post job_openings_url, params: { job_opening: attributes }, as: :json
      assert_response :created
    end
  end

  test "should handle job opening with all valid job types" do
    valid_job_types = %w[full-time part-time contract internship]
    
    valid_job_types.each do |job_type|
      attributes = @valid_attributes.merge(job_type: job_type)
      post job_openings_url, params: { job_opening: attributes }, as: :json
      assert_response :created
    end
  end

  test "should handle job opening with salary range" do
    attributes = @valid_attributes.merge(
      salary_min: 60000,
      salary_max: 90000
    )
    
    post job_openings_url, params: { job_opening: attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal 60000, json_response["salary_min"]
    assert_equal 90000, json_response["salary_max"]
  end

  test "should handle job opening without salary range" do
    attributes = @valid_attributes.except(:salary_min, :salary_max)
    
    post job_openings_url, params: { job_opening: attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_nil json_response["salary_min"]
    assert_nil json_response["salary_max"]
  end

  test "should handle job opening with applications count" do
    attributes = @valid_attributes.merge(applications: 5)
    
    post job_openings_url, params: { job_opening: attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal 5, json_response["applications"]
  end

  test "should handle job opening with negative applications count" do
    attributes = @valid_attributes.merge(applications: -1)
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Applications must be greater than or equal to 0"
  end

  test "should return job opening with all required fields" do
    get job_opening_url(@job_opening), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    required_fields = %w[id title department_id description requirements status location job_type vacancies salary_min salary_max experience skills posted applications created_at updated_at]
    
    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle job opening with missing optional fields" do
    minimal_attributes = {
      title: "Minimal Job",
      department_id: @department.id,
      description: "A minimal job description that meets the minimum length requirement.",
      requirements: "Basic requirements",
      status: "open",
      location: "Remote",
      job_type: "full-time",
      vacancies: 1,
      experience: "1-3 years",
      skills: "JavaScript",
      posted: Date.current
    }
    
    post job_openings_url, params: { job_opening: minimal_attributes }, as: :json
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:title], json_response["title"]
    assert_equal minimal_attributes[:department_id], json_response["department_id"]
    # Optional fields should be null
    assert_nil json_response["salary_min"]
    assert_nil json_response["salary_max"]
    assert_nil json_response["applications"]
  end

  test "should handle description that is too short" do
    invalid_attributes = @valid_attributes.merge(description: "Short")
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Description is too short (minimum is 20 characters)"
  end

  test "should handle missing required fields" do
    missing_required_attributes = {
      title: "Missing Required Fields",
      department_id: @department.id
      # Missing description, requirements, status, location, job_type, vacancies, experience, skills, posted
    }
    
    assert_no_difference('JobOpening.count') do
      post job_openings_url, params: { job_opening: missing_required_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Description can't be blank"
    assert_includes json_response["errors"], "Requirements can't be blank"
    assert_includes json_response["errors"], "Status can't be blank"
    assert_includes json_response["errors"], "Location can't be blank"
    assert_includes json_response["errors"], "Job type can't be blank"
    assert_includes json_response["errors"], "Vacancies can't be blank"
    assert_includes json_response["errors"], "Experience can't be blank"
    assert_includes json_response["errors"], "Skills can't be blank"
    assert_includes json_response["errors"], "Posted can't be blank"
  end
end
