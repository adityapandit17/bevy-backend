class Candidate < ApplicationRecord
  has_many :interviews, dependent: :destroy
  has_one :next_interview, -> {
    where("scheduled_date >= ?", Date.current)
      .order(:scheduled_date, :scheduled_time)
  }, class_name: "Interview"

  validates :name, presence: true
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

  def full_name
    name
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
