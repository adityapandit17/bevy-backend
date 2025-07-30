require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  def setup
    @candidate = Candidate.new(
      name: "John Doe",
      email: "john.doe@example.com",
      phone: "1234567890",
      position: "Software Engineer",
      department: "Engineering",
      experience: "5 years",
      location: "San Francisco, CA",
      status: "applied",
      applied_date: Date.current,
      last_contact: Date.current,
      resume: "resume.pdf",
      cover_letter: "cover_letter.pdf",
      notes: "Strong technical background",
      skills: "Ruby, Rails, JavaScript, React",
      education: "Bachelor's in Computer Science",
      current_company: "TechCorp",
      expected_salary: "80000",
      availability: "Immediate"
    )
  end

  test "should be valid with valid attributes" do
    assert @candidate.valid?
  end

  test "should require name" do
    @candidate.name = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:name], "can't be blank"
  end

  test "should require email" do
    @candidate.email = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:email], "can't be blank"
  end

  test "should validate email format" do
    @candidate.email = "invalid-email"
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:email], "is invalid"
  end

  test "should accept valid email formats" do
    valid_emails = [
      "test@example.com",
      "user.name@domain.co.uk",
      "user+tag@example.org"
    ]
    
    valid_emails.each do |email|
      @candidate.email = email
      assert @candidate.valid?, "#{email} should be valid"
    end
  end

  test "should require phone" do
    @candidate.phone = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:phone], "can't be blank"
  end

  test "should require position" do
    @candidate.position = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:position], "can't be blank"
  end

  test "should require department" do
    @candidate.department = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:department], "can't be blank"
  end

  test "should require status" do
    @candidate.status = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    @candidate.status = "invalid_status"
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:status], "is not included in the list"
  end

  test "should accept valid statuses" do
    valid_statuses = %w[applied screening interview technical final offered hired rejected]
    valid_statuses.each do |status|
      @candidate.status = status
      assert @candidate.valid?, "#{status} should be valid"
    end
  end

  test "should require applied_date" do
    @candidate.applied_date = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:applied_date], "can't be blank"
  end

  # Association tests
  test "should have many interviews" do
    assert_respond_to @candidate, :interviews
  end

  test "should destroy interviews when deleted" do
    @candidate.save!
    @candidate.interviews.create!(
      scheduled_date: Date.current + 1.week,
      scheduled_time: Time.current + 1.week,
      interview_type: "video",
      interviewer: "John Interviewer",
      status: "scheduled"
    )
    
    assert_difference('Interview.count', -1) do
      @candidate.destroy
    end
  end

  # Scope tests
  test "active scope should return non-hired and non-rejected candidates" do
    @candidate.save!
    
    hired_candidate = Candidate.create!(
      name: "Hired Person",
      email: "hired@example.com",
      phone: "1111111111",
      position: "Developer",
      department: "Engineering",
      status: "hired",
      applied_date: Date.current
    )
    
    rejected_candidate = Candidate.create!(
      name: "Rejected Person",
      email: "rejected@example.com",
      phone: "2222222222",
      position: "Developer",
      department: "Engineering",
      status: "rejected",
      applied_date: Date.current
    )
    
    assert_includes Candidate.active, @candidate
    assert_not_includes Candidate.active, hired_candidate
    assert_not_includes Candidate.active, rejected_candidate
  end

  test "by_status scope should filter by status" do
    @candidate.save!
    
    screening_candidate = Candidate.create!(
      name: "Screening Person",
      email: "screening@example.com",
      phone: "3333333333",
      position: "Developer",
      department: "Engineering",
      status: "screening",
      applied_date: Date.current
    )
    
    assert_includes Candidate.by_status("applied"), @candidate
    assert_not_includes Candidate.by_status("applied"), screening_candidate
  end

  test "recent scope should return candidates who applied in last 30 days" do
    @candidate.applied_date = 15.days.ago
    @candidate.save!
    
    old_candidate = Candidate.create!(
      name: "Old Person",
      email: "old@example.com",
      phone: "4444444444",
      position: "Developer",
      department: "Engineering",
      status: "applied",
      applied_date: 35.days.ago
    )
    
    assert_includes Candidate.recent, @candidate
    assert_not_includes Candidate.recent, old_candidate
  end

  test "by_department scope should filter by department" do
    @candidate.save!
    
    marketing_candidate = Candidate.create!(
      name: "Marketing Person",
      email: "marketing@example.com",
      phone: "5555555555",
      position: "Marketing Manager",
      department: "Marketing",
      status: "applied",
      applied_date: Date.current
    )
    
    assert_includes Candidate.by_department("Engineering"), @candidate
    assert_not_includes Candidate.by_department("Engineering"), marketing_candidate
  end

  # Instance method tests
  test "full_name should return name" do
    assert_equal "John Doe", @candidate.full_name
  end

  test "skills_list should return array of skills" do
    @candidate.skills = "Ruby, Rails, JavaScript, React"
    assert_equal ["Ruby", "Rails", "JavaScript", "React"], @candidate.skills_list
  end

  test "skills_list should return empty array for blank skills" do
    @candidate.skills = nil
    assert_equal [], @candidate.skills_list
    
    @candidate.skills = ""
    assert_equal [], @candidate.skills_list
  end

  test "skills_list= should set skills from array" do
    skills_array = ["Ruby", "Rails", "JavaScript"]
    @candidate.skills_list = skills_array
    assert_equal "Ruby, Rails, JavaScript", @candidate.skills
  end

  test "skills_list= should handle string input" do
    @candidate.skills_list = "Ruby, Rails"
    assert_equal "Ruby, Rails", @candidate.skills
  end

  test "next_interview should return upcoming interview" do
    @candidate.save!
    future_interview = @candidate.interviews.create!(
      scheduled_date: Date.current + 1.week,
      scheduled_time: Time.current + 1.week,
      interview_type: "video",
      interviewer: "John Interviewer",
      status: "scheduled"
    )
    
    past_interview = @candidate.interviews.create!(
      scheduled_date: Date.current - 1.week,
      scheduled_time: Time.current - 1.week,
      interview_type: "phone",
      interviewer: "Jane Interviewer",
      status: "completed"
    )
    
    assert_equal future_interview, @candidate.next_interview
  end

  test "next_interview should return nil when no upcoming interviews" do
    @candidate.save!
    past_interview = @candidate.interviews.create!(
      scheduled_date: Date.current - 1.week,
      scheduled_time: Time.current - 1.week,
      interview_type: "phone",
      interviewer: "Jane Interviewer",
      status: "completed"
    )
    
    assert_nil @candidate.next_interview
  end

  test "last_interview should return most recent interview" do
    @candidate.save!
    first_interview = @candidate.interviews.create!(
      scheduled_date: Date.current - 2.weeks,
      scheduled_time: Time.current - 2.weeks,
      interview_type: "phone",
      interviewer: "Jane Interviewer",
      status: "completed"
    )
    
    second_interview = @candidate.interviews.create!(
      scheduled_date: Date.current - 1.week,
      scheduled_time: Time.current - 1.week,
      interview_type: "video",
      interviewer: "John Interviewer",
      status: "completed"
    )
    
    assert_equal second_interview, @candidate.last_interview
  end

  test "interview_count should return number of interviews" do
    @candidate.save!
    @candidate.interviews.create!(
      scheduled_date: Date.current + 1.week,
      scheduled_time: Time.current + 1.week,
      interview_type: "video",
      interviewer: "John Interviewer",
      status: "scheduled"
    )
    
    @candidate.interviews.create!(
      scheduled_date: Date.current + 2.weeks,
      scheduled_time: Time.current + 2.weeks,
      interview_type: "onsite",
      interviewer: "Jane Interviewer",
      status: "scheduled"
    )
    
    assert_equal 2, @candidate.interview_count
  end

  test "days_since_applied should return days since applied date" do
    @candidate.applied_date = 5.days.ago
    assert_equal 5, @candidate.days_since_applied
  end

  test "days_since_last_contact should return days since last contact" do
    @candidate.last_contact = 3.days.ago
    assert_equal 3, @candidate.days_since_last_contact
  end

  test "days_since_last_contact should return nil when no last contact" do
    @candidate.last_contact = nil
    assert_nil @candidate.days_since_last_contact
  end

  # CRUD tests
  test "should be able to create candidate" do
    assert_difference('Candidate.count') do
      @candidate.save!
    end
  end

  test "should be able to update candidate" do
    @candidate.save!
    @candidate.name = "Jane Doe"
    @candidate.save!
    assert_equal "Jane Doe", @candidate.reload.name
  end

  test "should be able to delete candidate" do
    @candidate.save!
    assert_difference('Candidate.count', -1) do
      @candidate.destroy
    end
  end

  # Edge cases
  test "should handle skills with extra spaces" do
    @candidate.skills = "Ruby , Rails , JavaScript , React"
    assert_equal ["Ruby", "Rails", "JavaScript", "React"], @candidate.skills_list
  end

  test "should handle single skill" do
    @candidate.skills = "Ruby"
    assert_equal ["Ruby"], @candidate.skills_list
  end

  test "should handle empty skills string" do
    @candidate.skills = "   "
    assert_equal [], @candidate.skills_list
  end
end
