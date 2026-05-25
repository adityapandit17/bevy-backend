class CandidateSerializer < Panko::Serializer
  attributes :id, :job_opening_id, :first_name, :last_name, :date_of_birth, :email, :phone, :position, :department, :experience,
             :location, :status, :applied_date, :last_contact, :resume,
             :cover_letter, :notes, :education, :current_company,
             :expected_salary, :availability, :linkedin_url, :created_at, :updated_at

  # Computed attributes
  attributes :name, :skills, :interview_count, :days_since_applied,
             :days_since_last_contact

  # Associations
  has_many :interviews, serializer: InterviewSerializer
  has_one :next_interview, serializer: InterviewSerializer

  def name
    object.full_name
  end

  def skills
    object.skills_list
  end

  def interview_count
    object.interview_count
  end

  def days_since_applied
    object.days_since_applied
  end

  def days_since_last_contact
    object.days_since_last_contact
  end
end
