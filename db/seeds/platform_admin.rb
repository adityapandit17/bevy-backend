# frozen_string_literal: true

puts "Setting up platform admin users..."

platform_admin = PlatformAdminUser.find_or_create_by!(email: "admin@bevyhr.com") do |admin|
  admin.first_name = "Platform"
  admin.last_name = "Admin"
  admin.password = "admin123"
  admin.password_confirmation = "admin123"
  admin.role = "super_admin"
  admin.status = "active"
end

platform_admin.update!(
  password: "admin123",
  password_confirmation: "admin123"
) unless platform_admin.valid_password?("admin123")

puts "✓ Platform admin: admin@bevyhr.com / admin123"

support_admin = PlatformAdminUser.find_or_create_by!(email: "support@bevyhr.com") do |admin|
  admin.first_name = "Support"
  admin.last_name = "Agent"
  admin.password = "support123"
  admin.password_confirmation = "support123"
  admin.role = "support"
  admin.status = "active"
end

puts "✓ Platform support: support@bevyhr.com / support123"

puts "Ensuring default tenant company has SaaS fields..."
default_company = Company.find_by(code: "DEMO") || Company.order(:id).first
if default_company
  default_company.update!(
    status: "active",
    plan: "professional",
    contact_email: "admin@hrms.com",
    contact_name: "Super Admin"
  )
  puts "✓ Default company: #{default_company.name} (#{default_company.code})"
end

demo_companies = [
  { name: "GreenLeaf Retail", code: "GLR", industry: "retail", employee_count: "51-200", status: "active", plan: "starter" },
  { name: "Nova Finance", code: "NVF", industry: "finance", employee_count: "201-500", status: "active", plan: "enterprise" },
  { name: "Bright Labs", code: "BLB", industry: "technology", employee_count: "1-50", status: "trial", plan: "professional" },
  { name: "Summit Logistics", code: "SML", industry: "manufacturing", employee_count: "51-200", status: "pending", plan: "starter" }
]

demo_companies.each do |attrs|
  company = Company.find_or_create_by!(code: attrs[:code]) do |c|
    c.name = attrs[:name]
    c.industry = attrs[:industry]
    c.employee_count = attrs[:employee_count]
    c.timezone = "asia-kolkata"
    c.currency = "inr"
    c.country_code = "IN"
    c.status = attrs[:status]
    c.plan = attrs[:plan]
    c.trial_ends_at = attrs[:status] == "trial" ? 10.days.from_now : nil
  end
  company.update!(attrs.slice(:status, :plan).merge(
    trial_ends_at: attrs[:status] == "trial" ? 10.days.from_now : company.trial_ends_at
  ))
  puts "✓ Demo tenant: #{company.name} (#{company.status})"
end

puts "Platform admin seed completed!"
