class JobOpening < ApplicationRecord
  belongs_to :department

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 20 }
  validates :requirements, presence: true
  validates :status, presence: true, inclusion: { in: %w[open closed draft filled] }
  validates :location, presence: true
  validates :job_type, presence: true, inclusion: { in: %w[full-time part-time contract internship] }
  validates :vacancies, presence: true, numericality: { greater_than: 0 }
  validates :salary_min, numericality: { greater_than: 0 }, allow_nil: true
  validates :salary_max, numericality: { greater_than: 0 }, allow_nil: true
  validates :experience, presence: true
  validates :skills, presence: true
  validates :posted, presence: true
  validates :applications, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :salary_range_validity

  scope :open, -> { where(status: 'open') }
  scope :closed, -> { where(status: 'closed') }
  scope :draft, -> { where(status: 'draft') }
  scope :filled, -> { where(status: 'filled') }
  scope :recent, -> { where('posted >= ?', 30.days.ago) }
  scope :by_location, ->(location) { where(location: location) }
  scope :by_job_type, ->(job_type) { where(job_type: job_type) }
  scope :by_department, ->(department_id) { where(department_id: department_id) }
  scope :high_salary, -> { where('salary_max >= ?', 100000) }
  scope :entry_level, -> { where('salary_max <= ?', 50000) }

  def salary_range_validity
    return unless salary_min.present? && salary_max.present?
    
    if salary_min > salary_max
      errors.add(:salary_max, "must be greater than minimum salary")
    end
  end

  def salary_range
    return "Not specified" unless salary_min.present? && salary_max.present?
    "$#{salary_min.to_s(:delimited)} - $#{salary_max.to_s(:delimited)}"
  end

  def average_salary
    return nil unless salary_min.present? && salary_max.present?
    (salary_min + salary_max) / 2
  end

  def is_open?
    status == 'open'
  end

  def is_closed?
    status == 'closed'
  end

  def is_draft?
    status == 'draft'
  end

  def is_filled?
    status == 'filled'
  end

  def days_since_posted
    return nil unless posted
    (Date.current - posted).to_i
  end

  def is_recent?
    return false unless posted
    posted >= 7.days.ago
  end

  def is_urgent?
    return false unless posted
    posted <= 3.days.ago && applications.to_i < 5
  end

  def skills_list
    return [] if skills.blank?
    skills.split(',').map(&:strip)
  end

  def skills_list=(skill_list)
    self.skills = skill_list.is_a?(Array) ? skill_list.join(', ') : skill_list
  end

  def formatted_posted_date
    return "Not posted" unless posted
    posted.strftime("%B %d, %Y")
  end

  def status_color
    case status
    when 'open'
      'green'
    when 'closed'
      'red'
    when 'draft'
      'gray'
    when 'filled'
      'blue'
    else
      'gray'
    end
  end

  def status_label
    status.titleize
  end

  def job_type_label
    job_type.titleize
  end

  def display_title
    "#{title} - #{location}"
  end
end
