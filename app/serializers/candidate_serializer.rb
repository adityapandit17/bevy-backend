class CandidateSerializer < Panko::Serializer
  attributes :id, :name, :email, :phone, :position, :department, :experience,
             :location, :status, :applied_date, :last_contact, :resume,
             :cover_letter, :notes, :education, :current_company,
             :expected_salary, :availability, :created_at, :updated_at

  # Computed attributes
  attributes :skills, :interview_count, :days_since_applied,
             :days_since_last_contact

  # Associations
  has_many :interviews, serializer: InterviewSerializer
  has_one :next_interview, serializer: InterviewSerializer

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
