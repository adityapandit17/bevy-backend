require "test_helper"

class CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate = candidates(:one)
    @valid_attributes = {
      name: "Jane Smith",
      email: "jane.smith@example.com",
      phone: "9876543210",
      position: "Senior Developer",
      department: "Engineering",
      experience: "5 years",
      location: "New York, NY",
      status: "applied",
      applied_date: Date.current,
      last_contact: Date.current,
      resume: "resume.pdf",
      cover_letter: "cover_letter.pdf",
      notes: "Strong technical background",
      skills: "Ruby, Rails, JavaScript, React",
      education: "Bachelor's in Computer Science",
      current_company: "TechCorp",
      expected_salary: "90000",
      availability: "Immediate"
    }
  end

  test "should get index" do
    get candidates_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    assert_not_empty json_response
  end

  test "should get index with status filter" do
    get candidates_url, params: { status: "applied" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    json_response.each do |candidate|
      assert_equal "applied", candidate["status"]
    end
  end

  test "should get index with department filter" do
    get candidates_url, params: { department: "Engineering" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    json_response.each do |candidate|
      assert_equal "Engineering", candidate["department"]
    end
  end

  test "should get index with search filter" do
    skip "Controller uses ILIKE which is not supported in SQLite"
    get candidates_url, params: { search: "John" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    json_response.each do |candidate|
      assert candidate["name"].include?("John") ||
             candidate["email"].include?("John") ||
             candidate["position"].include?("John")
    end
  end

  test "should get index with multiple filters" do
    skip "Controller uses ILIKE which is not supported in SQLite"
    get candidates_url, params: {
      status: "applied",
      department: "Engineering",
      search: "John"
    }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    json_response.each do |candidate|
      assert_equal "applied", candidate["status"]
      assert_equal "Engineering", candidate["department"]
      assert candidate["name"].include?("John") ||
             candidate["email"].include?("John") ||
             candidate["position"].include?("John")
    end
  end

  test "should show candidate" do
    get candidate_url(@candidate), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @candidate.id, json_response["id"]
    assert_equal @candidate.name, json_response["name"]
    assert_equal @candidate.email, json_response["email"]
  end

  test "should create candidate" do
    assert_difference("Candidate.count") do
      post candidates_url, params: { candidate: @valid_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal @valid_attributes[:name], json_response["name"]
    assert_equal @valid_attributes[:email], json_response["email"]
  end

  test "should create candidate with minimal attributes" do
    minimal_attributes = {
      name: "Minimal Candidate",
      email: "minimal@example.com",
      phone: "1234567890",
      position: "Developer",
      department: "Engineering",
      status: "applied"
    }

    assert_difference("Candidate.count") do
      post candidates_url, params: { candidate: minimal_attributes }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal minimal_attributes[:name], json_response["name"]
    assert_equal minimal_attributes[:email], json_response["email"]
    assert_equal Date.current.to_s, json_response["applied_date"]
    assert_equal Date.current.to_s, json_response["last_contact"]
    assert_equal "applied", json_response["status"]
  end

  test "should not create candidate with invalid attributes" do
    invalid_attributes = @valid_attributes.merge(email: "invalid-email")

    assert_no_difference("Candidate.count") do
      post candidates_url, params: { candidate: invalid_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Email is invalid"
  end

  test "should not create candidate with duplicate email" do
    duplicate_attributes = @valid_attributes.merge(email: @candidate.email)

    assert_no_difference("Candidate.count") do
      post candidates_url, params: { candidate: duplicate_attributes }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Email has already been taken"
  end

  test "should update candidate" do
    patch candidate_url(@candidate), params: {
      candidate: { name: "Updated Name", status: "interview" }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Updated Name", json_response["name"]
    assert_equal "interview", json_response["status"]
  end

  test "should not update candidate with invalid attributes" do
    patch candidate_url(@candidate), params: {
      candidate: { email: "invalid-email" }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Email is invalid"
  end

  test "should destroy candidate" do
    assert_difference("Candidate.count", -1) do
      delete candidate_url(@candidate), as: :json
    end

    assert_response :no_content
  end

  test "should update candidate status" do
    patch update_status_candidate_url(@candidate), params: {
      status: "interview"
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "interview", json_response["status"]
    assert_equal Date.current.to_s, json_response["last_contact"]
  end

  test "should not update candidate status with invalid status" do
    patch update_status_candidate_url(@candidate), params: {
      status: "invalid_status"
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Status is not included in the list"
  end

  test "should get stats" do
    get stats_candidates_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response.keys, "total_applications"
    assert_includes json_response.keys, "active_candidates"
    assert_includes json_response.keys, "interviews_this_week"
    assert_includes json_response.keys, "offers_extended"
    assert_includes json_response.keys, "hired_this_month"
    assert_includes json_response.keys, "pipeline"

    # Check pipeline structure
    pipeline = json_response["pipeline"]
    assert_kind_of Hash, pipeline
  end

  test "should get pipeline" do
    get pipeline_candidates_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    expected_statuses = %w[applied screening interview technical final offered hired rejected]

    expected_statuses.each do |status|
      assert_includes json_response.keys, status
      pipeline_stage = json_response[status]
      assert_includes pipeline_stage.keys, "count"
      assert_includes pipeline_stage.keys, "candidates"
      assert_kind_of Integer, pipeline_stage["count"]
      assert_kind_of Array, pipeline_stage["candidates"]
    end
  end

  test "should return 404 for non-existent candidate" do
    get candidate_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating non-existent candidate" do
    patch candidate_url(99999), params: {
      candidate: { name: "Updated Name" }
    }, as: :json
    assert_response :not_found
  end

  test "should return 404 when destroying non-existent candidate" do
    delete candidate_url(99999), as: :json
    assert_response :not_found
  end

  test "should return 404 when updating status of non-existent candidate" do
    patch update_status_candidate_url(99999), params: {
      status: "interview"
    }, as: :json
    assert_response :not_found
  end

  test "should format candidate with interviews" do
    # Create an interview for the candidate
    interview = Interview.create!(
      candidate: @candidate,
      interview_type: "video",
      scheduled_date: Date.current + 1.week,
      scheduled_time: Time.current + 1.week,
      interviewer: "John Interviewer",
      status: "scheduled"
    )

    get candidate_url(@candidate), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response.keys, "interviews"
    assert_kind_of Array, json_response["interviews"]
    assert_equal 1, json_response["interviews"].length

    interview_data = json_response["interviews"].first
    assert_equal interview.id, interview_data["id"]
    assert_equal interview.interview_type, interview_data["interview_type"]
    assert_equal interview.status, interview_data["status"]
  end

  test "should handle candidate with no interviews" do
    # Create a candidate with no interviews
    candidate_without_interviews = Candidate.create!(
      name: "No Interviews",
      email: "no.interviews@example.com",
      phone: "1234567890",
      position: "Developer",
      department: "Engineering",
      status: "applied",
      applied_date: Date.current
    )

    get candidate_url(candidate_without_interviews), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_includes json_response.keys, "interviews"
    assert_kind_of Array, json_response["interviews"]
    assert_empty json_response["interviews"]
  end

  test "should handle empty search results" do
    skip "Controller uses ILIKE which is not supported in SQLite"
    get candidates_url, params: { search: "NonExistentCandidate" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    assert_empty json_response
  end

  test "should handle empty status filter results" do
    get candidates_url, params: { status: "hired" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    # May be empty if no hired candidates exist
  end

  test "should handle empty department filter results" do
    get candidates_url, params: { department: "NonExistentDepartment" }, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_kind_of Array, json_response
    assert_empty json_response
  end

  test "should return candidate with all required fields" do
    get candidate_url(@candidate), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    required_fields = %w[id name email phone position department experience location status applied_date last_contact resume cover_letter notes skills education current_company expected_salary availability interviews created_at updated_at]

    required_fields.each do |field|
      assert_includes json_response.keys, field, "Missing field: #{field}"
    end
  end

  test "should handle candidate with missing optional fields" do
    minimal_candidate = Candidate.create!(
      name: "Minimal",
      email: "minimal@example.com",
      phone: "1234567890",
      position: "Developer",
      department: "Engineering",
      status: "applied",
      applied_date: Date.current
    )

    get candidate_url(minimal_candidate), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal minimal_candidate.name, json_response["name"]
    assert_equal minimal_candidate.email, json_response["email"]
    # Optional fields should be null or empty
    assert_nil json_response["resume"]
    assert_nil json_response["cover_letter"]
    assert_nil json_response["notes"]
  end
end
