# frozen_string_literal: true

# Platform SaaS seed data — pricing, CRM, campaigns, subscription requests
puts "Seeding platform SaaS data..."

pricing_plans = [
  {
    slug: "starter", name: "Starter", description: "Small teams getting started with HR",
    monthly_price: 2999, annual_price: 30_590, max_employees: 50, per_seat_price: 60, position: 1,
    features: [ "Core HR", "Attendance", "Leave", "Payroll basics" ]
  },
  {
    slug: "professional", name: "Professional", description: "Growing companies with full HR stack",
    monthly_price: 7999, annual_price: 81_590, max_employees: 250, per_seat_price: 32, position: 2, popular: true,
    features: [ "ATS", "Performance", "Reports", "Chat" ]
  },
  {
    slug: "enterprise", name: "Enterprise", description: "Custom pricing and unlimited scale",
    monthly_price: 19_999, annual_price: 203_990, max_employees: 10_000, per_seat_price: 2, position: 3,
    features: [ "SSO", "Custom roles", "API", "Dedicated support" ]
  }
]

pricing_plans.each do |attrs|
  plan = PricingPlan.find_or_initialize_by(slug: attrs[:slug])
  plan.assign_attributes(attrs.merge(published: true))
  plan.save!
  puts "✓ Pricing plan: #{plan.name}"
end

PlatformSetting::DEFAULTS.each do |key, value|
  PlatformSetting.find_or_create_by!(key: key) { |s| s.value = value }
end
puts "✓ Platform settings initialized"

if PlatformInquiry.count.zero?
  [
    { company_name: "Acme Corp", contact_name: "Jane Doe", email: "jane@acme.com", source: "website", plan_interest: "professional", estimated_seats: 120, status: "new", notes: "Interested in ATS module" },
    { company_name: "Pixel Works", contact_name: "Raj Patel", email: "raj@pixelworks.in", source: "linkedin", plan_interest: "starter", estimated_seats: 25, status: "contacted", assignee: "Support Agent" },
    { company_name: "Horizon Tech", contact_name: "Maria Chen", email: "maria@horizontech.com", source: "webinar", plan_interest: "enterprise", estimated_seats: 800, status: "qualified", assignee: "Platform Admin" }
  ].each { |attrs| PlatformInquiry.create!(attrs) }
  puts "✓ Sample inquiries created"
end

if PlatformFollowUp.count.zero? && PlatformInquiry.exists?
  inquiry = PlatformInquiry.first
  PlatformFollowUp.create!(
    platform_inquiry: inquiry,
    company_name: inquiry.company_name,
    assignee: "Support Agent",
    due_date: 2.days.ago.to_date,
    status: "overdue",
    follow_up_type: "call",
    notes: "Schedule demo call"
  )
  puts "✓ Sample follow-ups created"
end

if PlatformCampaign.count.zero?
  [
    { name: "Q2 HR Leaders Webinar", channel: "webinar", audience: "HR Directors 200+", status: "active", sent_count: 1420, conversions: 18, budget: 45_000, start_date: 2.months.ago.to_date, end_date: 1.month.from_now.to_date },
    { name: "LinkedIn SMB Outreach", channel: "linkedin", audience: "SMB founders India", status: "active", sent_count: 890, conversions: 11, budget: 25_000, start_date: 1.month.ago.to_date },
    { name: "Summer Trial Promo", channel: "email", audience: "Trial users expiring in 7d", status: "draft", budget: 15_000, start_date: 2.weeks.from_now.to_date }
  ].each { |attrs| PlatformCampaign.create!(attrs) }
  puts "✓ Sample campaigns created"
end

if PlatformAnnouncement.count.zero?
  admin = PlatformAdminUser.first
  PlatformAnnouncement.create!(
    title: "Welcome to BevyHR Platform Admin",
    message: "Manage tenants, subscriptions, and CRM from this console.",
    audience: "all",
    status: "active",
    starts_at: Time.current,
    platform_admin_user: admin
  )
  puts "✓ Sample announcement created"
end

pending_company = Company.find_by(code: "SML")
if SubscriptionRequest.count.zero?
  SubscriptionRequest.create!(
    company: pending_company,
    company_name: pending_company&.name || "Summit Logistics",
    request_type: "new_tenant",
    plan: "starter",
    seats: 30,
    amount: 2999,
    billing_cycle: "monthly",
    status: "pending",
    requested_by: "ops@summitlogistics.com",
    notes: "Awaiting PO from finance"
  )
  puts "✓ Sample subscription request created"
end

Company.where(status: "trial").find_each do |company|
  CompanyFeatureFlag::DEFAULT_FLAGS.each do |key|
    CompanyFeatureFlag.find_or_create_by!(company: company, key: key) do |flag|
      flag.enabled = key == "chat"
    end
  end
end

puts "Platform SaaS seed completed!"
