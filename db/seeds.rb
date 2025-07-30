# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create departments if they don't exist
departments = [
  { name: "Engineering" },
  { name: "Marketing" },
  { name: "HR" },
  { name: "Finance" },
  { name: "Operations" },
  { name: "Sales" },
  { name: "Product" },
  { name: "Design" }
]

departments.each do |dept|
  Department.find_or_create_by!(name: dept[:name])
end

# Create employees if they don't exist
employees = [
  {
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@company.com",
    phone: "+91 98765 43210",
    department_id: Department.find_by(name: "Engineering").id,
    designation: "Senior Software Engineer",
    date_of_joining: Date.current - 30.days,
    status: "active"
  },
  {
    first_name: "Jane",
    last_name: "Smith",
    email: "jane.smith@company.com",
    phone: "+91 87654 32109",
    department_id: Department.find_by(name: "Marketing").id,
    designation: "Marketing Manager",
    date_of_joining: Date.current - 15.days,
    status: "active"
  },
  {
    first_name: "Mike",
    last_name: "Johnson",
    email: "mike.johnson@company.com",
    phone: "+91 76543 21098",
    department_id: Department.find_by(name: "HR").id,
    designation: "HR Specialist",
    date_of_joining: Date.current - 7.days,
    status: "active"
  }
]

employees.each do |emp|
  Employee.find_or_create_by!(email: emp[:email]) do |employee|
    employee.assign_attributes(emp)
  end
end

# Create onboarding employees
onboarding_employees = [
  {
    employee_id: Employee.find_by(email: "john.doe@company.com").id,
    start_date: Date.current + 5.days,
    status: "in_progress",
    progress: 65,
    notes: "John is progressing well through the onboarding process."
  },
  {
    employee_id: Employee.find_by(email: "jane.smith@company.com").id,
    start_date: Date.current + 10.days,
    status: "pending",
    progress: 0,
    notes: "Jane's onboarding will start next week."
  }
]

onboarding_employees.each do |oe|
  OnboardingEmployee.find_or_create_by!(employee_id: oe[:employee_id]) do |onboarding_employee|
    onboarding_employee.assign_attributes(oe)
  end
end

# Create onboarding tasks for existing onboarding employees
OnboardingEmployee.all.each do |oe|
  next if oe.onboarding_tasks.any?
  
  default_tasks = [
    {
      title: "Complete HR Paperwork",
      description: "Fill out all required HR forms and documentation",
      category: "HR",
      priority: "high",
      due_date: oe.start_date - 5.days,
      assigned_to: "HR Team",
      is_completed: true,
      documents: "Employment contract, Tax forms, Emergency contacts"
    },
    {
      title: "IT Setup",
      description: "Set up computer, email, and necessary software",
      category: "IT",
      priority: "high",
      due_date: oe.start_date - 3.days,
      assigned_to: "IT Team",
      is_completed: true,
      documents: "Computer setup checklist, Software licenses"
    },
    {
      title: "Department Introduction",
      description: "Meet with team members and understand department processes",
      category: "Department",
      priority: "medium",
      due_date: oe.start_date + 2.days,
      assigned_to: "Department Manager",
      is_completed: false,
      documents: "Department handbook, Process documentation"
    },
    {
      title: "Training Sessions",
      description: "Attend company-wide training sessions",
      category: "Training",
      priority: "medium",
      due_date: oe.start_date + 5.days,
      assigned_to: "Training Team",
      is_completed: false,
      documents: "Training schedule, Course materials"
    },
    {
      title: "Performance Goals Setting",
      description: "Set initial performance goals with manager",
      category: "Performance",
      priority: "medium",
      due_date: oe.start_date + 10.days,
      assigned_to: "Manager",
      is_completed: false,
      documents: "Goal setting template, Performance review schedule"
    }
  ]

  default_tasks.each do |task_attrs|
    OnboardingTask.create!(
      onboarding_employee: oe,
      **task_attrs
    )
  end
end

# Create candidates
candidates = [
  {
    name: "Sarah Wilson",
    email: "sarah.wilson@email.com",
    phone: "+91 65432 10987",
    position: "Frontend Developer",
    department: "Engineering",
    experience: "3 years",
    location: "Mumbai",
    status: "interview_scheduled",
    applied_date: Date.current - 5.days,
    last_contact: Date.current - 1.day,
    resume: "sarah_wilson_resume.pdf",
    cover_letter: "sarah_wilson_cover.pdf",
    notes: "Strong React skills, good communication",
    skills: "React, JavaScript, TypeScript, HTML, CSS",
    education: "B.Tech Computer Science",
    current_company: "TechCorp",
    expected_salary: "₹8,00,000",
    availability: "2 weeks notice"
  },
  {
    name: "David Brown",
    email: "david.brown@email.com",
    phone: "+91 54321 09876",
    position: "Product Manager",
    department: "Product",
    experience: "5 years",
    location: "Bangalore",
    status: "application_review",
    applied_date: Date.current - 3.days,
    last_contact: Date.current - 2.days,
    resume: "david_brown_resume.pdf",
    cover_letter: "david_brown_cover.pdf",
    notes: "Experienced in B2B SaaS products",
    skills: "Product Strategy, User Research, Agile, Analytics",
    education: "MBA Marketing",
    current_company: "SaaS Solutions",
    expected_salary: "₹12,00,000",
    availability: "1 month notice"
  },
  {
    name: "Lisa Chen",
    email: "lisa.chen@email.com",
    phone: "+91 43210 98765",
    position: "UX Designer",
    department: "Design",
    experience: "4 years",
    location: "Delhi",
    status: "offer_sent",
    applied_date: Date.current - 10.days,
    last_contact: Date.current,
    resume: "lisa_chen_resume.pdf",
    cover_letter: "lisa_chen_cover.pdf",
    notes: "Excellent portfolio, strong user research skills",
    skills: "Figma, Sketch, User Research, Prototyping",
    education: "B.Des Interaction Design",
    current_company: "Design Studio",
    expected_salary: "₹9,00,000",
    availability: "Immediate"
  }
]

candidates.each do |candidate_attrs|
  Candidate.find_or_create_by!(email: candidate_attrs[:email]) do |candidate|
    candidate.assign_attributes(candidate_attrs)
  end
end

# Create interviews
interviews = [
  {
    candidate: Candidate.find_by(email: "sarah.wilson@email.com"),
    interviewer: "John Doe",
    interview_type: "video",
    scheduled_date: Date.current + 2.days,
    scheduled_time: Time.parse("10:00"),
    status: "scheduled",
    notes: "Technical assessment focusing on React and JavaScript"
  },
  {
    candidate: Candidate.find_by(email: "david.brown@email.com"),
    interviewer: "Jane Smith",
    interview_type: "video",
    scheduled_date: Date.current + 3.days,
    scheduled_time: Time.parse("14:00"),
    status: "scheduled",
    notes: "Behavioral interview to assess leadership and communication skills"
  },
  {
    candidate: Candidate.find_by(email: "lisa.chen@email.com"),
    interviewer: "Mike Johnson",
    interview_type: "onsite",
    scheduled_date: Date.current - 2.days,
    scheduled_time: Time.parse("11:00"),
    status: "completed",
    feedback: "Excellent portfolio, strong design thinking, recommended for next round",
    notes: "Portfolio review and design challenge discussion"
  }
]

interviews.each do |interview_attrs|
  Interview.find_or_create_by!(
    candidate: interview_attrs[:candidate],
    scheduled_date: interview_attrs[:scheduled_date],
    scheduled_time: interview_attrs[:scheduled_time]
  ) do |interview|
    interview.assign_attributes(interview_attrs)
  end
end

# Create assets
assets = [
  {
    name: "MacBook Pro 16-inch",
    asset_type: "laptop",
    serial_number: "MBP2024001",
    model: "MacBook Pro 16-inch M2",
    brand: "Apple",
    purchase_date: Date.current - 6.months,
    warranty_expiry: Date.current + 1.year + 6.months,
    purchase_cost: 2499.00,
    current_value: 2200.00,
    status: "assigned",
    location: "Engineering Department",
    department: "Engineering",
    notes: "Assigned to senior developer",
    condition: "excellent",
    last_maintenance: Date.current - 2.months,
    next_maintenance: Date.current + 4.months,
    employee_id: Employee.find_by(email: "john.doe@company.com").id
  },
  {
    name: "Dell XPS 15",
    asset_type: "laptop",
    serial_number: "DXP2024002",
    model: "XPS 15 9520",
    brand: "Dell",
    purchase_date: Date.current - 4.months,
    warranty_expiry: Date.current + 1.year + 8.months,
    purchase_cost: 1899.00,
    current_value: 1700.00,
    status: "assigned",
    location: "Marketing Department",
    department: "Marketing",
    notes: "Assigned to marketing manager",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "jane.smith@company.com").id
  },
  {
    name: "HP LaserJet Pro",
    asset_type: "printer",
    serial_number: "HPL2024003",
    model: "LaserJet Pro M404n",
    brand: "HP",
    purchase_date: Date.current - 8.months,
    warranty_expiry: Date.current + 1.year + 4.months,
    purchase_cost: 299.00,
    current_value: 250.00,
    status: "available",
    location: "HR Department",
    department: "HR",
    notes: "Shared printer for HR team",
    condition: "good",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months
  },
  {
    name: "Cisco Switch",
    asset_type: "network",
    serial_number: "CIS2024004",
    model: "Catalyst 2960",
    brand: "Cisco",
    purchase_date: Date.current - 12.months,
    warranty_expiry: Date.current + 2.years,
    purchase_cost: 899.00,
    current_value: 750.00,
    status: "available",
    location: "Server Room",
    department: "IT",
    notes: "Network infrastructure",
    condition: "excellent",
    last_maintenance: Date.current - 2.months,
    next_maintenance: Date.current + 4.months
  },
  {
    name: "iPhone 15 Pro",
    asset_type: "mobile",
    serial_number: "IPH2024005",
    model: "iPhone 15 Pro 256GB",
    brand: "Apple",
    purchase_date: Date.current - 3.months,
    warranty_expiry: Date.current + 1.year + 9.months,
    purchase_cost: 1199.00,
    current_value: 1100.00,
    status: "assigned",
    location: "Sales Department",
    department: "Sales",
    notes: "Assigned to sales representative",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "jane.smith@company.com").id
  },
  {
    name: "Dell OptiPlex Desktop",
    asset_type: "desktop",
    serial_number: "DOP2024006",
    model: "OptiPlex 7010",
    brand: "Dell",
    purchase_date: Date.current - 8.months,
    warranty_expiry: Date.current + 1.year + 4.months,
    purchase_cost: 799.00,
    current_value: 650.00,
    status: "available",
    location: "Finance Department",
    department: "Finance",
    notes: "Finance team desktop",
    condition: "good",
    last_maintenance: Date.current - 4.months,
    next_maintenance: Date.current + 2.months
  }
]

assets.each do |asset_attrs|
  Asset.find_or_create_by!(serial_number: asset_attrs[:serial_number]) do |asset|
    asset.assign_attributes(asset_attrs)
  end
end

# Create asset allocations for assigned assets
Asset.where.not(employee_id: nil).each do |asset|
  next if asset.asset_allocations.active.any?
  
  AssetAllocation.create!(
    asset: asset,
    employee: asset.employee,
    assigned_date: asset.purchase_date + 1.week,
    status: "active",
    notes: "Initial assignment"
  )
end

# Create maintenance records
maintenance_records = [
  {
    asset: Asset.find_by(serial_number: "MBP2024001"),
    maintenance_date: Date.current - 2.months,
    maintenance_type: "routine",
    description: "Software updates and hardware inspection",
    cost: 0.00,
    performed_by: "IT Team"
  },
  {
    asset: Asset.find_by(serial_number: "HPL2024003"),
    maintenance_date: Date.current - 1.month,
    maintenance_type: "repair",
    description: "Paper feed mechanism repair",
    cost: 150.00,
    performed_by: "External Vendor"
  },
  {
    asset: Asset.find_by(serial_number: "CIS2024004"),
    maintenance_date: Date.current - 2.months,
    maintenance_type: "routine",
    description: "Firmware update and security patches",
    cost: 0.00,
    performed_by: "Network Team"
  },
  {
    asset: Asset.find_by(serial_number: "DXP2024002"),
    maintenance_date: Date.current - 3.months,
    maintenance_type: "upgrade",
    description: "RAM upgrade to 32GB",
    cost: 200.00,
    performed_by: "IT Team"
  }
]

maintenance_records.each do |record_attrs|
  MaintenanceRecord.find_or_create_by!(
    asset: record_attrs[:asset],
    maintenance_date: record_attrs[:maintenance_date],
    maintenance_type: record_attrs[:maintenance_type]
  ) do |record|
    record.assign_attributes(record_attrs)
  end
end

# Create employee documents
employee_documents = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Employment Contract",
    document_type: "contract",
    upload_date: Date.current - 30.days,
    expiry_date: nil,
    status: "active",
    file_size: "245760",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Aadhaar Card",
    document_type: "id_proof",
    upload_date: Date.current - 30.days,
    expiry_date: Date.current + 5.years,
    status: "active",
    file_size: "512000",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Resume",
    document_type: "resume",
    upload_date: Date.current - 30.days,
    expiry_date: nil,
    status: "active",
    file_size: "102400",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "Employment Contract",
    document_type: "contract",
    upload_date: Date.current - 15.days,
    expiry_date: nil,
    status: "active",
    file_size: "245760",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "PAN Card",
    document_type: "id_proof",
    upload_date: Date.current - 15.days,
    expiry_date: nil,
    status: "active",
    file_size: "256000",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    name: "Employment Contract",
    document_type: "contract",
    upload_date: Date.current - 7.days,
    expiry_date: nil,
    status: "active",
    file_size: "245760",
    uploaded_by: "HR Manager"
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    name: "Driving License",
    document_type: "id_proof",
    upload_date: Date.current - 7.days,
    expiry_date: Date.current + 2.years,
    status: "active",
    file_size: "384000",
    uploaded_by: "HR Manager"
  }
]

employee_documents.each do |doc_attrs|
  EmployeeDocument.find_or_create_by!(
    employee: doc_attrs[:employee],
    name: doc_attrs[:name]
  ) do |doc|
    doc.assign_attributes(doc_attrs)
  end
end

# Create performance reviews
performance_reviews = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    period: "Q4 2024",
    rating: 4.2,
    reviewer: "Engineering Manager",
    review_date: Date.current - 1.month,
    comments: "Excellent technical skills and team collaboration. Shows strong leadership potential.",
    goals: "Lead a major feature development, Mentor junior developers",
    achievements: "Completed 3 major features, Reduced bug count by 40%",
    areas_for_improvement: "Public speaking skills, Documentation practices"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    period: "Q4 2024",
    rating: 4.5,
    reviewer: "Marketing Director",
    review_date: Date.current - 2.weeks,
    comments: "Outstanding performance in campaign management and team leadership.",
    goals: "Increase brand awareness by 25%, Launch 2 new campaigns",
    achievements: "Exceeded campaign targets by 30%, Improved team productivity",
    areas_for_improvement: "Data analysis skills, Cross-department collaboration"
  }
]

performance_reviews.each do |review_attrs|
  PerformanceReview.find_or_create_by!(
    employee: review_attrs[:employee],
    period: review_attrs[:period]
  ) do |review|
    review.assign_attributes(review_attrs)
  end
end

# Create performance goals
performance_goals = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    title: "Lead Feature Development",
    description: "Take ownership of the new user dashboard feature",
    target: "Complete development and testing by Q2 2025",
    progress: 75,
    status: "in_progress",
    due_date: Date.current + 2.months
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    title: "Mentor Junior Developers",
    description: "Provide guidance and support to 2 junior developers",
    target: "Help them complete their first major features",
    progress: 60,
    status: "in_progress",
    due_date: Date.current + 3.months
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    title: "Increase Brand Awareness",
    description: "Develop and execute campaigns to increase brand visibility",
    target: "Achieve 25% increase in brand recognition",
    progress: 40,
    status: "in_progress",
    due_date: Date.current + 4.months
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    title: "Launch New Campaign",
    description: "Plan and launch 2 new marketing campaigns",
    target: "Successfully launch campaigns with measurable results",
    progress: 20,
    status: "in_progress",
    due_date: Date.current + 2.months
  }
]

performance_goals.each do |goal_attrs|
  PerformanceGoal.find_or_create_by!(
    employee: goal_attrs[:employee],
    title: goal_attrs[:title]
  ) do |goal|
    goal.assign_attributes(goal_attrs)
  end
end

# Create timesheets
timesheets = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    date: Date.current - 1.day,
    hours: 8.5,
    project: "User Dashboard",
    task: "Frontend Development",
    status: "approved",
    approved_by: "Engineering Manager",
    notes: "Completed user profile component"
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    date: Date.current - 2.days,
    hours: 8.0,
    project: "User Dashboard",
    task: "Backend API Development",
    status: "approved",
    approved_by: "Engineering Manager",
    notes: "Implemented user data API endpoints"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    date: Date.current - 1.day,
    hours: 8.0,
    project: "Q1 Campaign",
    task: "Campaign Planning",
    status: "approved",
    approved_by: "Marketing Director",
    notes: "Finalized campaign strategy and budget"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    date: Date.current - 2.days,
    hours: 7.5,
    project: "Brand Awareness",
    task: "Content Creation",
    status: "approved",
    approved_by: "Marketing Director",
    notes: "Created social media content calendar"
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    date: Date.current - 1.day,
    hours: 8.0,
    project: "HR Processes",
    task: "Policy Review",
    status: "pending",
    notes: "Reviewed and updated employee handbook"
  }
]

timesheets.each do |timesheet_attrs|
  Timesheet.find_or_create_by!(
    employee: timesheet_attrs[:employee],
    date: timesheet_attrs[:date],
    project: timesheet_attrs[:project]
  ) do |timesheet|
    timesheet.assign_attributes(timesheet_attrs)
  end
end

# Create employee benefits
employee_benefits = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Health Insurance",
    benefit_type: "health_insurance",
    provider: "Max Bupa",
    coverage: "Family coverage up to ₹5,00,000",
    start_date: Date.current - 30.days,
    end_date: Date.current + 1.year - 30.days,
    status: "active",
    cost: 2500.00
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Life Insurance",
    benefit_type: "life_insurance",
    provider: "LIC",
    coverage: "₹50,00,000 term life insurance",
    start_date: Date.current - 30.days,
    end_date: Date.current + 10.years - 30.days,
    status: "active",
    cost: 500.00
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "Health Insurance",
    benefit_type: "health_insurance",
    provider: "Max Bupa",
    coverage: "Individual coverage up to ₹3,00,000",
    start_date: Date.current - 15.days,
    end_date: Date.current + 1.year - 15.days,
    status: "active",
    cost: 1500.00
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "Dental Insurance",
    benefit_type: "dental_insurance",
    provider: "Dental Care Plus",
    coverage: "Annual coverage up to ₹25,000",
    start_date: Date.current - 15.days,
    end_date: Date.current + 1.year - 15.days,
    status: "active",
    cost: 800.00
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    name: "Health Insurance",
    benefit_type: "health_insurance",
    provider: "Max Bupa",
    coverage: "Individual coverage up to ₹3,00,000",
    start_date: Date.current - 7.days,
    end_date: Date.current + 1.year - 7.days,
    status: "active",
    cost: 1500.00
  }
]

employee_benefits.each do |benefit_attrs|
  EmployeeBenefit.find_or_create_by!(
    employee: benefit_attrs[:employee],
    name: benefit_attrs[:name]
  ) do |benefit|
    benefit.assign_attributes(benefit_attrs)
  end
end

# Create employee trainings
employee_trainings = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Advanced React Development",
    training_type: "technical",
    provider: "Udemy",
    start_date: Date.current - 2.weeks,
    end_date: Date.current + 2.weeks,
    status: "in_progress",
    progress: 60,
    cost: 1500.00,
    skills: "React Hooks, Context API, Performance Optimization"
  },
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    name: "Leadership Skills",
    training_type: "soft_skills",
    provider: "Internal Training",
    start_date: Date.current - 1.month,
    end_date: Date.current + 2.months,
    status: "in_progress",
    progress: 30,
    cost: 0.00,
    skills: "Team Management, Communication, Decision Making"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "Digital Marketing Certification",
    training_type: "certification",
    provider: "Google Digital Garage",
    start_date: Date.current - 3.weeks,
    end_date: Date.current + 1.week,
    status: "in_progress",
    progress: 80,
    cost: 2000.00,
    skills: "SEO, SEM, Social Media Marketing, Analytics"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    name: "Data Analysis for Marketing",
    training_type: "technical",
    provider: "Coursera",
    start_date: Date.current - 1.week,
    end_date: Date.current + 3.weeks,
    status: "not_started",
    progress: 0,
    cost: 1200.00,
    skills: "Excel, Google Analytics, Data Visualization"
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    name: "HR Compliance Training",
    training_type: "compliance",
    provider: "SHRM",
    start_date: Date.current - 5.days,
    end_date: Date.current + 1.month,
    status: "in_progress",
    progress: 25,
    cost: 3000.00,
    skills: "Labor Laws, Compliance, Employee Relations"
  }
]

employee_trainings.each do |training_attrs|
  EmployeeTraining.find_or_create_by!(
    employee: training_attrs[:employee],
    name: training_attrs[:name]
  ) do |training|
    training.assign_attributes(training_attrs)
  end
end

# Create leave requests
leave_requests = [
  {
    employee: Employee.find_by(email: "john.doe@company.com"),
    leave_type: "annual",
    start_date: Date.current + 1.week,
    end_date: Date.current + 1.week + 4.days,
    reason: "Family vacation",
    status: "approved"
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    leave_type: "sick",
    start_date: Date.current - 3.days,
    end_date: Date.current - 1.day,
    reason: "Not feeling well",
    status: "approved"
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    leave_type: "personal",
    start_date: Date.current + 2.weeks,
    end_date: Date.current + 2.weeks + 1.day,
    reason: "Personal appointment",
    status: "pending"
  }
]

leave_requests.each do |leave_attrs|
  LeaveRequest.find_or_create_by!(
    employee: leave_attrs[:employee],
    start_date: leave_attrs[:start_date],
    end_date: leave_attrs[:end_date]
  ) do |leave|
    leave.assign_attributes(leave_attrs)
  end
end

# Offboarding Employees
puts "Creating offboarding employees..."

# Create offboarding employees
offboarding_employees = [
  {
    employee: employees[0], # Sarah Johnson
    last_working_day: Date.current + 5.days,
    status: "in_progress",
    progress: 65,
    assigned_to: "Mike Chen",
    notes: "Moving to another company",
    start_date: Date.current - 10.days
  },
  {
    employee: employees[1], # David Kim
    last_working_day: Date.current + 15.days,
    status: "pending",
    progress: 0,
    assigned_to: "Lisa Wang",
    notes: "Personal reasons",
    start_date: Date.current - 2.days
  },
  {
    employee: employees[2], # Mike Chen
    last_working_day: Date.current - 5.days,
    status: "completed",
    progress: 100,
    assigned_to: "John Smith",
    notes: "Completed successfully",
    start_date: Date.current - 20.days
  }
]

offboarding_employees.each do |offboarding_data|
  offboarding_employee = OffboardingEmployee.create!(offboarding_data)
  
  # Create default tasks for each offboarding employee
  default_tasks = [
    {
      title: "Return Company Laptop",
      description: "Return all company equipment including laptop, charger, and accessories",
      category: "Equipment",
      priority: "high",
      due_date: offboarding_employee.last_working_day - 1.day,
      assigned_to: "IT Department",
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? true : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day - 2.days : (offboarding_employee.status == "in_progress" ? offboarding_employee.last_working_day - 3.days : nil)
    },
    {
      title: "Exit Interview",
      description: "Conduct exit interview with HR manager",
      category: "HR",
      priority: "high",
      due_date: offboarding_employee.last_working_day - 1.day,
      assigned_to: "HR Department",
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? true : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day - 1.day : (offboarding_employee.status == "in_progress" ? offboarding_employee.last_working_day - 2.days : nil)
    },
    {
      title: "Knowledge Transfer",
      description: "Transfer knowledge and handover ongoing projects",
      category: "Knowledge Transfer",
      priority: "medium",
      due_date: offboarding_employee.last_working_day,
      assigned_to: offboarding_employee.assigned_to,
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? false : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day : nil
    },
    {
      title: "Cancel Benefits",
      description: "Cancel health insurance and other benefits",
      category: "Benefits",
      priority: "medium",
      due_date: offboarding_employee.last_working_day,
      assigned_to: "HR Department",
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? false : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day : nil
    },
    {
      title: "Return Access Cards",
      description: "Return office access cards and keys",
      category: "Access",
      priority: "high",
      due_date: offboarding_employee.last_working_day,
      assigned_to: "Facilities Department",
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? false : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day : nil
    },
    {
      title: "Final Documentation",
      description: "Complete final documentation and handover reports",
      category: "Documentation",
      priority: "medium",
      due_date: offboarding_employee.last_working_day,
      assigned_to: offboarding_employee.assigned_to,
      is_completed: offboarding_employee.status == "completed" ? true : (offboarding_employee.status == "in_progress" ? false : false),
      completed_date: offboarding_employee.status == "completed" ? offboarding_employee.last_working_day : nil
    }
  ]

  default_tasks.each do |task_attrs|
    offboarding_employee.offboarding_tasks.create!(task_attrs)
  end
end

puts "Created #{OffboardingEmployee.count} offboarding employees with #{OffboardingTask.count} tasks"

puts "Seed data created successfully!"
puts "Created #{Department.count} departments"
puts "Created #{Employee.count} employees"
puts "Created #{OnboardingEmployee.count} onboarding employees"
puts "Created #{OnboardingTask.count} onboarding tasks"
puts "Created #{Candidate.count} candidates"
puts "Created #{Interview.count} interviews"
puts "Created #{Asset.count} assets"
puts "Created #{AssetAllocation.count} asset allocations"
puts "Created #{MaintenanceRecord.count} maintenance records"
puts "Created #{EmployeeDocument.count} employee documents"
puts "Created #{PerformanceReview.count} performance reviews"
puts "Created #{PerformanceGoal.count} performance goals"
puts "Created #{Timesheet.count} timesheets"
puts "Created #{EmployeeBenefit.count} employee benefits"
puts "Created #{EmployeeTraining.count} employee trainings"
puts "Created #{LeaveRequest.count} leave requests"