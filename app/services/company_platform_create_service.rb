# frozen_string_literal: true

class CompanyPlatformCreateService
  class CreateError < StandardError; end

  def initialize(params)
    @params = params
  end

  def call
    validate_inputs!

    ActiveRecord::Base.transaction do
      company = create_company!

      if params[:create_admin] != false && admin_email.present?
        ActsAsTenant.with_tenant(company) do
          DepartmentSeeder.seed!
          employee = create_admin_employee!(company)
          user = create_admin_user!(employee)
          assign_super_admin_role!(user)
        end
      end

      company
    end
  rescue ActiveRecord::RecordInvalid => e
    raise CreateError, e.record.errors.full_messages.join(", ")
  end

  private

  attr_reader :params

  def validate_inputs!
    raise CreateError, "Company name is required" if params[:name].blank?
    raise CreateError, "Industry is required" if params[:industry].blank?

    if admin_email.present? && params[:admin_password].to_s.length < 8
      raise CreateError, "Admin password must be at least 8 characters"
    end
  end

  def admin_email
    params[:admin_email].to_s.downcase.strip.presence
  end

  def create_company!
    name = params[:name].to_s.strip
    code = params[:code].presence || unique_company_code(name)
    status = params[:status].presence || "trial"
    trial_days = (params[:trial_days] || PlatformSetting.get("default_trial_days")).to_i

    Company.create!(
      name: name,
      code: code,
      industry: params[:industry],
      employee_count: params[:employee_count].presence || "1-50",
      timezone: params[:timezone].presence || "asia-kolkata",
      currency: params[:currency].presence || "inr",
      country_code: params[:country_code].presence || "IN",
      address: params[:address],
      status: status,
      plan: normalized_plan,
      trial_ends_at: status == "trial" ? trial_days.days.from_now : params[:trial_ends_at],
      max_employees: params[:max_employees] || plan_max_employees,
      contact_email: admin_email || params[:contact_email],
      contact_name: params[:contact_name] || params[:admin_first_name].to_s,
      billing_cycle: params[:billing_cycle].presence || "monthly",
      renews_at: status == "active" ? 1.month.from_now : nil
    )
  end

  def create_admin_employee!(company)
    Employee.create!(
      first_name: params[:admin_first_name].presence || "Admin",
      last_name: params[:admin_last_name].presence || company.name,
      email: admin_email,
      phone: params[:admin_phone].presence || "9999999999",
      status: "active",
      date_of_joining: Date.current,
      department: Department.find_by!(name: "General"),
      designation: "Company Administrator"
    )
  end

  def create_admin_user!(employee)
    password = params[:admin_password].presence || SecureRandom.hex(8)
    User.create!(
      employee: employee,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      password: password,
      password_confirmation: password,
      status: "active"
    )
  end

  def assign_super_admin_role!(user)
    role = Role.system_roles.find_by(name: "Super Admin")
    raise CreateError, "Super Admin role is not configured" unless role

    user.roles << role unless user.roles.include?(role)
  end

  def normalized_plan
    plan = params[:plan].to_s.downcase
    Company::PLANS.include?(plan) ? plan : "starter"
  end

  def plan_max_employees
    pricing = PricingPlan.find_by(slug: normalized_plan)
    return pricing.max_employees if pricing

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
