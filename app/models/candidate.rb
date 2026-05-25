class Candidate < ApplicationRecord
  belongs_to :job_opening, optional: true
  has_many :interviews, dependent: :destroy
  has_one :next_interview, -> {
    where("scheduled_date >= ?", Date.current)
      .order(:scheduled_date, :scheduled_time)
  }, class_name: "Interview"

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :position, presence: true
  validates :department, presence: true
  validates :status, presence: true, inclusion: { in: %w[applied screening interview technical final offered hired rejected] }
  validates :applied_date, presence: true

  scope :active, -> { where.not(status: %w[hired rejected]) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { where("applied_date >= ?", 30.days.ago) }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :archived, -> { where(archived: true) }
  scope :not_archived, -> { where(archived: false) }
  scope :for_job_opening, ->(job_opening_id) { where(job_opening_id: job_opening_id) }
  scope :search_text, ->(query) {
    return all if query.blank?

    term = "%#{query.downcase}%"
    where(
      "LOWER(first_name) LIKE :t OR LOWER(last_name) LIKE :t OR LOWER(email) LIKE :t OR LOWER(CONCAT(first_name, ' ', last_name)) LIKE :t",
      t: term
    )
  }
  scope :with_skills, ->(skills_query) {
    return all if skills_query.blank?

    skills_query.to_s.split(",").map(&:strip).reject(&:blank?).reduce(all) do |scope, skill|
      scope.where("LOWER(skills) LIKE ?", "%#{skill.downcase}%")
    end
  }
  scope :applied_on_or_after, ->(date) {
    return all if date.blank?

    where("applied_date >= ?", date)
  }
  scope :applied_on_or_before, ->(date) {
    return all if date.blank?

    where("applied_date <= ?", date)
  }

  def full_name
    [ first_name, last_name ].compact.join(" ").strip
  end

  # Backward compatibility method
  def name
    full_name
  end

  def skills_list
    return [] if skills.blank?

    skills.split(",").map(&:strip)
  end

  def skills_list=(skill_list)
    self.skills = skill_list.is_a?(Array) ? skill_list.join(", ") : skill_list
  end

  def last_interview
    interviews.order(:scheduled_date, :scheduled_time).last
  end

  def interview_count
    interviews.size
  end

  def days_since_applied
    (Date.current - applied_date).to_i
  end

  def days_since_last_contact
    return nil unless last_contact

    (Date.current - last_contact).to_i
  end
end
