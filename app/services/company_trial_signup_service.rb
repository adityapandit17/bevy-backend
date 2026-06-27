# frozen_string_literal: true

class CompanyTrialSignupService
  class SignupError < StandardError; end

  DEFAULT_TIMEZONE = "asia-kolkata"
  DEFAULT_CURRENCY = "inr"
  DEFAULT_COUNTRY = "IN"

  def initialize(params)
    @params = params
  end

  def call
    validate_inputs!

    ActiveRecord::Base.transaction do
      company = create_company!

      ActsAsTenant.with_tenant(company) do
        DepartmentSeeder.seed!
        employee = create_admin_employee!
        user = create_admin_user!(employee)
        assign_super_admin_role!(user)

        { company: company, user: user, token: JwtService.generate_token(user) }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    raise SignupError, e.record.errors.full_messages.join(", ")
  end

  private

  attr_reader :params

  def validate_inputs!
    %i[company_name admin_email admin_password admin_first_name admin_last_name].each do |key|
      raise SignupError, "#{key.to_s.humanize} is required" if params[key].blank?
    end

    raise SignupError, "Password must be at least 8 characters" if params[:admin_password].to_s.length < 8
  end

  def create_company!
    name = params[:company_name].to_s.strip
    code = params[:company_code].presence || unique_company_code(name)

    Company.create!(
      name: name,
      code: code,
      industry: params[:industry].presence || "technology",
      employee_count: params[:employee_count].presence || "1-50",
      timezone: params[:timezone].presence || DEFAULT_TIMEZONE,
      currency: params[:currency].presence || DEFAULT_CURRENCY,
      country_code: params[:country_code].presence || DEFAULT_COUNTRY,
      address: params[:address],
      status: "trial",
      plan: normalized_plan,
      trial_ends_at: Company::TRIAL_DAYS.days.from_now,
      max_employees: plan_max_employees,
      contact_email: params[:admin_email].to_s.downcase.strip,
      contact_name: "#{params[:admin_first_name]} #{params[:admin_last_name]}".strip
    )
  end

  def create_admin_employee!
    Employee.create!(
      first_name: params[:admin_first_name].to_s.strip,
      last_name: params[:admin_last_name].to_s.strip,
      email: params[:admin_email].to_s.downcase.strip,
      phone: params[:admin_phone].presence || "9999999999",
      status: "active",
      date_of_joining: Date.current,
      department: default_department,
      designation: "Company Administrator"
    )
  end

  def create_admin_user!(employee)
    User.create!(
      employee: employee,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      password: params[:admin_password],
      password_confirmation: params[:admin_password],
      status: "active"
    )
  end

  def assign_super_admin_role!(user)
    role = Role.system_roles.find_by(name: "Super Admin")
    raise SignupError, "Super Admin role is not configured" unless role

    user.roles << role unless user.roles.include?(role)
  end

  def default_department
    Department.find_by!(name: "General")
  end

  def normalized_plan
    plan = params[:plan].to_s.downcase
    Company::PLANS.include?(plan) ? plan : "starter"
  end

  def plan_max_employees
    case normalized_plan
    when "professional" then 200
    when "enterprise" then 10_000
    else 50
    end
  end

  def unique_company_code(name)
    base = name.to_s.parameterize.upcase.gsub(/[^A-Z0-9]/, "")[0, 6].presence || "CO"
    candidate = base
    suffix = 0

    while Company.exists?(code: candidate)
      suffix += 1
      candidate = "#{base[0, 4]}#{suffix}"
    end

    candidate
  end
end
