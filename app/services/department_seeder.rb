# frozen_string_literal: true

class DepartmentSeeder
  DEFAULT_NAMES = [
    "General",
    "Engineering",
    "Marketing",
    "HR",
    "Finance",
    "Operations",
    "Sales",
    "Product",
    "Design"
  ].freeze

  def self.default_names
    DEFAULT_NAMES
  end

  def self.seed!(names: DEFAULT_NAMES)
    names.map do |name|
      Department.find_or_create_by!(name: name)
    end
  end
end
