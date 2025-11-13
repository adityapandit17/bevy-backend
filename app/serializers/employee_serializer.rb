class EmployeeSerializer < Panko::Serializer
  # Basic attributes
  attributes :id, :first_name, :last_name, :email, :phone, :designation,
             :date_of_joining, :date_of_birth, :status, :created_at, :updated_at

  # Computed attributes
  attributes :name, :full_name, :initials, :avatar_url, :department_name,
             :status_label, :status_color, :tenure_summary, :formatted_hire_date,
             :manager_name, :direct_reports_count

  # Associations
  has_one :department, serializer: DepartmentSerializer
  has_one :manager, serializer: EmployeeSerializer
  has_many :direct_reports, serializer: EmployeeSerializer

  def name
    object.name
  end

  def full_name
    object.full_name
  end

  def initials
    object.initials
  end

  def avatar_url
    object.avatar_url
  end

  def department_name
    object.department_name
  end

  def status_label
    object.status_label
  end

  def status_color
    object.status_color
  end

  def tenure_summary
    object.tenure_summary
  end

  def formatted_hire_date
    object.formatted_hire_date
  end

  def manager_name
    object.manager&.name
  end

  def direct_reports_count
    object.direct_reports.count
  end
end

