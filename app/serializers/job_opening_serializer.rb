class JobOpeningSerializer < Panko::Serializer
  attributes :id, :title, :description, :requirements, :status, :location,
             :job_type, :vacancies, :salary_min, :salary_max, :experience,
             :skills, :posted, :applications, :created_at, :updated_at,
             :public_slug, :public_apply_url, :publicly_available

  # Computed attributes
  attributes :salary_range, :average_salary, :days_since_posted,
             :is_recent, :is_urgent, :status_color, :status_label,
             :job_type_label, :display_title, :formatted_posted_date,
             :skills_list, :department_id, :department_name

  # Associations
  has_one :department, serializer: DepartmentSerializer

  def salary_range
    object.salary_range
  end

  def average_salary
    object.average_salary
  end

  def days_since_posted
    object.days_since_posted
  end

  def is_recent
    object.is_recent?
  end

  def is_urgent
    object.is_urgent?
  end

  def status_color
    object.status_color
  end

  def status_label
    object.status_label
  end

  def job_type_label
    object.job_type_label
  end

  def display_title
    object.display_title
  end

  def formatted_posted_date
    object.formatted_posted_date
  end

  def skills_list
    object.skills_list
  end

  def department_id
    object.department_id
  end

  def department_name
    object.department&.name
  end

  def public_apply_url
    return nil unless object.publicly_available? && object.public_slug.present?

    base = ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
    "#{base}#{object.public_apply_path}"
  end

  def publicly_available
    object.publicly_available?
  end
end
