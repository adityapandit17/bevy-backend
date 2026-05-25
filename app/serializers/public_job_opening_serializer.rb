# frozen_string_literal: true

class PublicJobOpeningSerializer < Panko::Serializer
  attributes :title, :description, :requirements, :location, :job_type,
             :experience, :skills, :posted, :department_name, :skills_list,
             :job_type_label, :formatted_posted_date, :salary_range

  def department_name
    object.department&.name
  end

  def skills_list
    object.skills_list
  end

  def job_type_label
    object.job_type_label
  end

  def formatted_posted_date
    object.formatted_posted_date
  end

  def salary_range
    object.salary_range
  end
end
