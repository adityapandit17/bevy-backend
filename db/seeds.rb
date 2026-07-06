# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Setting up default tenant company..."
default_company = Company.find_or_create_by!(code: "DEMO") do |company|
  company.name = "BevyHR Demo"
  company.industry = "technology"
  company.employee_count = "51-200"
  company.timezone = "asia-kolkata"
  company.currency = "inr"
  company.country_code = "IN"
  company.status = "active"
  company.plan = "professional"
  company.contact_email = "admin@hrms.com"
  company.contact_name = "Super Admin"
end

puts "Seeding tenant data for #{default_company.name} (#{default_company.code})..."

ActsAsTenant.with_tenant(default_company) do
# Create departments if they don't exist
DepartmentSeeder.seed!

# Create employees if they don't exist
employees = [
  # Engineering Department
  {
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@company.com",
    phone: "+91 98765 43210",
    department_id: Department.find_by(name: "Engineering").id,
    designation: "Senior Software Engineer",
    date_of_joining: Date.current - 30.days,
    date_of_birth: Date.new(1990, 3, 15),
    status: "active"
  },
  {
    first_name: "Alice",
    last_name: "Johnson",
    email: "alice.johnson@company.com",
    phone: "+91 98765 43211",
    department_id: Department.find_by(name: "Engineering").id,
    designation: "Software Engineer",
    date_of_joining: Date.current - 20.days,
    status: "active"
  },
  {
    first_name: "Bob",
    last_name: "Wilson",
    email: "bob.wilson@company.com",
    phone: "+91 98765 43212",
    department_id: Department.find_by(name: "Engineering").id,
    designation: "Tech Lead",
    date_of_joining: Date.current - 60.days,
    status: "active"
  },
  {
    first_name: "Carol",
    last_name: "Brown",
    email: "carol.brown@company.com",
    phone: "+91 98765 43213",
    department_id: Department.find_by(name: "Engineering").id,
    designation: "DevOps Engineer",
    date_of_joining: Date.current - 45.days,
    status: "active"
  },

  # Marketing Department
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
    first_name: "David",
    last_name: "Lee",
    email: "david.lee@company.com",
    phone: "+91 87654 32110",
    department_id: Department.find_by(name: "Marketing").id,
    designation: "Content Writer",
    date_of_joining: Date.current - 25.days,
    status: "active"
  },
  {
    first_name: "Emma",
    last_name: "Davis",
    email: "emma.davis@company.com",
    phone: "+91 87654 32111",
    department_id: Department.find_by(name: "Marketing").id,
    designation: "Social Media Manager",
    date_of_joining: Date.current - 10.days,
    status: "active"
  },

  # HR Department
  {
    first_name: "Mike",
    last_name: "Johnson",
    email: "mike.johnson@company.com",
    phone: "+91 76543 21098",
    department_id: Department.find_by(name: "HR").id,
    designation: "HR Specialist",
    date_of_joining: Date.current - 7.days,
    status: "active"
  },
  {
    first_name: "Sarah",
    last_name: "Miller",
    email: "sarah.miller@company.com",
    phone: "+91 76543 21099",
    department_id: Department.find_by(name: "HR").id,
    designation: "HR Manager",
    date_of_joining: Date.current - 90.days,
    status: "active"
  },

  # Finance Department
  {
    first_name: "Tom",
    last_name: "Anderson",
    email: "tom.anderson@company.com",
    phone: "+91 65432 10987",
    department_id: Department.find_by(name: "Finance").id,
    designation: "Finance Manager",
    date_of_joining: Date.current - 120.days,
    status: "active"
  },
  {
    first_name: "Lisa",
    last_name: "Garcia",
    email: "lisa.garcia@company.com",
    phone: "+91 65432 10988",
    department_id: Department.find_by(name: "Finance").id,
    designation: "Accountant",
    date_of_joining: Date.current - 35.days,
    status: "active"
  },

  # Sales Department
  {
    first_name: "Mark",
    last_name: "Taylor",
    email: "mark.taylor@company.com",
    phone: "+91 54321 09876",
    department_id: Department.find_by(name: "Sales").id,
    designation: "Sales Manager",
    date_of_joining: Date.current - 75.days,
    status: "active"
  },
  {
    first_name: "Rachel",
    last_name: "White",
    email: "rachel.white@company.com",
    phone: "+91 54321 09877",
    department_id: Department.find_by(name: "Sales").id,
    designation: "Sales Executive",
    date_of_joining: Date.current - 40.days,
    status: "active"
  },

  # Product Department
  {
    first_name: "Kevin",
    last_name: "Martinez",
    email: "kevin.martinez@company.com",
    phone: "+91 43210 98765",
    department_id: Department.find_by(name: "Product").id,
    designation: "Product Manager",
    date_of_joining: Date.current - 50.days,
    status: "active"
  },

  # Design Department
  {
    first_name: "Amy",
    last_name: "Rodriguez",
    email: "amy.rodriguez@company.com",
    phone: "+91 32109 87654",
    department_id: Department.find_by(name: "Design").id,
    designation: "UI/UX Designer",
    date_of_joining: Date.current - 30.days,
    status: "active"
  },

  # Operations Department
  {
    first_name: "Chris",
    last_name: "Lopez",
    email: "chris.lopez@company.com",
    phone: "+91 21098 76543",
    department_id: Department.find_by(name: "Operations").id,
    designation: "Operations Manager",
    date_of_joining: Date.current - 100.days,
    status: "active"
  }
]

employees.each do |emp|
  Employee.find_or_create_by!(email: emp[:email]) do |employee|
    employee.assign_attributes(emp)
    # Add random date of birth (age between 22-55)
    age = rand(22..55)
    employee.date_of_birth = Date.current - age.years - rand(0..365).days
    employee.phone = "9876543212"
  end
end

# Create salary structures for all employees
puts "Creating salary structures..."
salary_data = {
  "Senior Software Engineer" => { basic: 1000000, hra: 200000, allowances: 200000, deductions: 50000 },
  "Software Engineer" => { basic: 700000, hra: 150000, allowances: 150000, deductions: 35000 },
  "Tech Lead" => { basic: 1300000, hra: 250000, allowances: 250000, deductions: 60000 },
  "DevOps Engineer" => { basic: 900000, hra: 180000, allowances: 180000, deductions: 40000 },
  "Marketing Manager" => { basic: 800000, hra: 160000, allowances: 160000, deductions: 38000 },
  "Content Writer" => { basic: 400000, hra: 80000, allowances: 80000, deductions: 20000 },
  "Social Media Manager" => { basic: 500000, hra: 100000, allowances: 100000, deductions: 25000 },
  "HR Manager" => { basic: 900000, hra: 180000, allowances: 180000, deductions: 40000 },
  "HR Specialist" => { basic: 600000, hra: 120000, allowances: 120000, deductions: 30000 },
  "Finance Manager" => { basic: 1000000, hra: 200000, allowances: 200000, deductions: 45000 },
  "Accountant" => { basic: 500000, hra: 100000, allowances: 100000, deductions: 25000 },
  "Sales Manager" => { basic: 700000, hra: 150000, allowances: 150000, deductions: 35000 },
  "Sales Executive" => { basic: 400000, hra: 100000, allowances: 100000, deductions: 20000 },
  "Product Manager" => { basic: 1200000, hra: 220000, allowances: 220000, deductions: 50000 },
  "UI/UX Designer" => { basic: 700000, hra: 140000, allowances: 140000, deductions: 32000 },
  "Operations Manager" => { basic: 800000, hra: 160000, allowances: 160000, deductions: 38000 }
}

Employee.all.each do |employee|
  salary_info = salary_data[employee.designation]
  if salary_info
    SalaryStructure.find_or_create_by!(employee: employee) do |ss|
      ss.basic = salary_info[:basic]
      ss.hra = salary_info[:hra]
      ss.allowances = salary_info[:allowances]
      ss.deductions = salary_info[:deductions]
      ss.effective_from = employee.date_of_joining
    end
  end
end

# Create payroll records for all employees
puts "Creating payroll records..."
Employee.all.each do |employee|
  salary_structure = employee.salary_structures.first

  if salary_structure
    gross_salary = salary_structure.basic + salary_structure.hra + salary_structure.allowances
    net_salary = gross_salary - salary_structure.deductions

    # Create payroll for current month
    Payroll.find_or_create_by!(
      employee: employee,
      month: Date.current.strftime("%B %Y")
    ) do |payroll|
      payroll.gross_salary = gross_salary
      payroll.net_salary = net_salary
      payroll.status = "processed"
    end

    # Create payroll for previous month
    Payroll.find_or_create_by!(
      employee: employee,
      month: 1.month.ago.strftime("%B %Y")
    ) do |payroll|
      payroll.gross_salary = gross_salary
      payroll.net_salary = net_salary
      payroll.status = "processed"
    end
  end
end

# Create attendance records for all employees
puts "Creating attendance records..."
# Employee.all.each do |employee|
#   # Create attendance records for the last 30 days
#   (0..29).each do |day_offset|
#     date = Date.current - day_offset.days
#     next if date.saturday? || date.sunday? # Skip weekends

#     AttendanceRecord.find_or_create_by!(
#       employee: employee,
#       date: date
#     ) do |attendance|
#       attendance.check_in = Time.parse("09:00") + rand(0..30).minutes
#       attendance.check_out = Time.parse("18:00") + rand(-30..30).minutes
#       attendance.status = [ "present", "late", "early_departure" ].sample
#     end
#   end
# end

# Create job openings
puts "Creating job openings..."
job_openings = [
  {
    title: "Senior Frontend Developer",
    department: Department.find_by(name: "Engineering"),
    description: "We are looking for a Senior Frontend Developer with 5+ years of experience in React, TypeScript, and modern web technologies.",
    requirements: "5+ years React experience, TypeScript, Redux, CSS/SCSS, Git, Agile methodologies",
    skills: "React, TypeScript, JavaScript, HTML, CSS, Redux, Git",
    location: "Bangalore",
    job_type: "full-time",
    experience: "5-8 years",
    salary_min: 1200000,
    salary_max: 1800000,
    posted: Date.current - 5.days,
    status: "open",
    vacancies: 2,
    applications: 15
  },
  {
    title: "Marketing Specialist",
    department: Department.find_by(name: "Marketing"),
    description: "Join our marketing team to drive growth and brand awareness through innovative campaigns and strategies.",
    requirements: "3+ years marketing experience, Digital marketing, Content creation, Analytics",
    skills: "Digital Marketing, Content Writing, SEO, Social Media, Analytics, Campaign Management",
    location: "Mumbai",
    job_type: "full-time",
    experience: "3-5 years",
    salary_min: 600000,
    salary_max: 900000,
    posted: Date.current - 3.days,
    status: "open",
    vacancies: 1,
    applications: 8
  },
  {
    title: "HR Business Partner",
    department: Department.find_by(name: "HR"),
    description: "Support business growth by providing strategic HR guidance and implementing people programs.",
    requirements: "4+ years HR experience, Employee relations, Performance management, HR policies",
    skills: "HR Management, Employee Relations, Performance Management, HR Policies, Recruitment",
    location: "Delhi",
    job_type: "full-time",
    experience: "4-6 years",
    salary_min: 800000,
    salary_max: 1200000,
    posted: Date.current - 7.days,
    status: "open",
    vacancies: 1,
    applications: 12
  },
  {
    title: "Financial Analyst",
    department: Department.find_by(name: "Finance"),
    description: "Analyze financial data and provide insights to support business decision making.",
    requirements: "2+ years finance experience, Financial modeling, Excel, Accounting principles",
    skills: "Financial Analysis, Excel, Financial Modeling, Accounting, Budgeting, Forecasting",
    location: "Chennai",
    job_type: "full-time",
    experience: "2-4 years",
    salary_min: 500000,
    salary_max: 750000,
    posted: Date.current - 10.days,
    status: "open",
    vacancies: 2,
    applications: 20
  },
  {
    title: "Sales Development Representative",
    department: Department.find_by(name: "Sales"),
    description: "Generate new business opportunities and build relationships with potential clients.",
    requirements: "1+ years sales experience, Communication skills, CRM experience, Target driven",
    skills: "Sales, CRM, Communication, Lead Generation, Customer Relationship Management",
    location: "Pune",
    job_type: "full-time",
    experience: "1-3 years",
    salary_min: 400000,
    salary_max: 600000,
    posted: Date.current - 2.days,
    status: "open",
    vacancies: 3,
    applications: 25
  },
  {
    title: "Product Designer",
    department: Department.find_by(name: "Design"),
    description: "Design user-centered products and experiences that delight our customers.",
    requirements: "3+ years design experience, UI/UX design, Design tools, User research",
    skills: "UI Design, UX Design, Figma, Sketch, User Research, Prototyping, Design Systems",
    location: "Hyderabad",
    job_type: "full-time",
    experience: "3-5 years",
    salary_min: 700000,
    salary_max: 1100000,
    posted: Date.current - 4.days,
    status: "open",
    vacancies: 1,
    applications: 18
  },
  {
    title: "DevOps Engineer",
    department: Department.find_by(name: "Engineering"),
    description: "Build and maintain our cloud infrastructure and deployment pipelines.",
    requirements: "3+ years DevOps experience, AWS/Azure, Docker, Kubernetes, CI/CD",
    skills: "AWS, Docker, Kubernetes, CI/CD, Terraform, Linux, Python, Monitoring",
    location: "Bangalore",
    job_type: "full-time",
    experience: "3-6 years",
    salary_min: 1000000,
    salary_max: 1500000,
    posted: Date.current - 6.days,
    status: "open",
    vacancies: 1,
    applications: 10
  },
  {
    title: "Operations Coordinator",
    department: Department.find_by(name: "Operations"),
    description: "Coordinate daily operations and ensure smooth business processes.",
    requirements: "2+ years operations experience, Process improvement, Project management",
    skills: "Operations Management, Process Improvement, Project Management, Data Analysis",
    location: "Kolkata",
    job_type: "full-time",
    experience: "2-4 years",
    salary_min: 450000,
    salary_max: 650000,
    posted: Date.current - 8.days,
    status: "open",
    vacancies: 1,
    applications: 14
  }
]

job_openings.each do |job_attrs|
  JobOpening.find_or_create_by!(
    title: job_attrs[:title],
    department: job_attrs[:department]
  ) do |job|
    job.assign_attributes(job_attrs)
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
    first_name: "Sarah",
    last_name: "Wilson",
    email: "sarah.wilson@email.com",
    phone: "+91 65432 10987",
    position: "Senior Frontend Developer",
    department: "Engineering",
    experience: "5 years",
    location: "Mumbai",
    status: "interview",
    applied_date: Date.current - 5.days,
    last_contact: Date.current - 1.day,
    resume: "sarah_wilson_resume.pdf",
    cover_letter: "sarah_wilson_cover.pdf",
    notes: "Strong React skills, good communication",
    skills: "React, JavaScript, TypeScript, HTML, CSS, Redux",
    education: "B.Tech Computer Science",
    current_company: "TechCorp",
    expected_salary: "₹12,00,000",
    availability: "2 weeks notice"
  },
  {
    first_name: "David",
    last_name: "Brown",
    email: "david.brown@email.com",
    phone: "+91 54321 09876",
    position: "Product Manager",
    department: "Product",
    experience: "5 years",
    location: "Bangalore",
    status: "screening",
    applied_date: Date.current - 3.days,
    last_contact: Date.current - 2.days,
    resume: "david_brown_resume.pdf",
    cover_letter: "david_brown_cover.pdf",
    notes: "Experienced in B2B SaaS products",
    skills: "Product Strategy, User Research, Agile, Analytics",
    education: "MBA Marketing",
    current_company: "SaaS Solutions",
    expected_salary: "₹15,00,000",
    availability: "1 month notice"
  },
  {
    first_name: "Lisa",
    last_name: "Chen",
    email: "lisa.chen@email.com",
    phone: "+91 43210 98765",
    position: "Product Designer",
    department: "Design",
    experience: "4 years",
    location: "Delhi",
    status: "offered",
    applied_date: Date.current - 10.days,
    last_contact: Date.current,
    resume: "lisa_chen_resume.pdf",
    cover_letter: "lisa_chen_cover.pdf",
    notes: "Excellent portfolio, strong user research skills",
    skills: "Figma, Sketch, User Research, Prototyping, Design Systems",
    education: "B.Des Interaction Design",
    current_company: "Design Studio",
    expected_salary: "₹10,00,000",
    availability: "Immediate"
  },
  {
    first_name: "Michael",
    last_name: "Rodriguez",
    email: "michael.rodriguez@email.com",
    phone: "+91 32109 87654",
    position: "Marketing Specialist",
    department: "Marketing",
    experience: "3 years",
    location: "Mumbai",
    status: "interview",
    applied_date: Date.current - 4.days,
    last_contact: Date.current - 1.day,
    resume: "michael_rodriguez_resume.pdf",
    cover_letter: "michael_rodriguez_cover.pdf",
    notes: "Strong digital marketing background",
    skills: "Digital Marketing, SEO, Social Media, Content Creation, Analytics",
    education: "BBA Marketing",
    current_company: "Digital Agency",
    expected_salary: "₹7,00,000",
    availability: "3 weeks notice"
  },
  {
    first_name: "Jennifer",
    last_name: "Kim",
    email: "jennifer.kim@email.com",
    phone: "+91 21098 76543",
    position: "HR Business Partner",
    department: "HR",
    experience: "4 years",
    location: "Delhi",
    status: "screening",
    applied_date: Date.current - 6.days,
    last_contact: Date.current - 2.days,
    resume: "jennifer_kim_resume.pdf",
    cover_letter: "jennifer_kim_cover.pdf",
    notes: "Strong employee relations experience",
    skills: "HR Management, Employee Relations, Performance Management, HR Policies",
    education: "MBA HR",
    current_company: "HR Consultancy",
    expected_salary: "₹9,00,000",
    availability: "1 month notice"
  },
  {
    first_name: "Robert",
    last_name: "Johnson",
    email: "robert.johnson@email.com",
    phone: "+91 10987 65432",
    position: "Financial Analyst",
    department: "Finance",
    experience: "2 years",
    location: "Chennai",
    status: "interview",
    applied_date: Date.current - 7.days,
    last_contact: Date.current - 1.day,
    resume: "robert_johnson_resume.pdf",
    cover_letter: "robert_johnson_cover.pdf",
    notes: "Strong analytical skills, CFA candidate",
    skills: "Financial Analysis, Excel, Financial Modeling, Accounting, Budgeting",
    education: "B.Com Finance",
    current_company: "Investment Bank",
    expected_salary: "₹6,00,000",
    availability: "2 weeks notice"
  },
  {
    first_name: "Amanda",
    last_name: "Davis",
    email: "amanda.davis@email.com",
    phone: "+91 09876 54321",
    position: "Sales Development Representative",
    department: "Sales",
    experience: "2 years",
    location: "Pune",
    status: "screening",
    applied_date: Date.current - 2.days,
    last_contact: Date.current - 1.day,
    resume: "amanda_davis_resume.pdf",
    cover_letter: "amanda_davis_cover.pdf",
    notes: "High energy, target-driven professional",
    skills: "Sales, CRM, Communication, Lead Generation, Customer Relationship",
    education: "BBA Sales",
    current_company: "Sales Company",
    expected_salary: "₹5,00,000",
    availability: "Immediate"
  },
  {
    first_name: "Kevin",
    last_name: "Park",
    email: "kevin.park@email.com",
    phone: "+91 98765 43210",
    position: "DevOps Engineer",
    department: "Engineering",
    experience: "4 years",
    location: "Bangalore",
    status: "interview",
    applied_date: Date.current - 8.days,
    last_contact: Date.current - 1.day,
    resume: "kevin_park_resume.pdf",
    cover_letter: "kevin_park_cover.pdf",
    notes: "Strong cloud infrastructure experience",
    skills: "AWS, Docker, Kubernetes, CI/CD, Terraform, Linux, Python",
    education: "B.Tech Computer Science",
    current_company: "Cloud Solutions",
    expected_salary: "₹13,00,000",
    availability: "1 month notice"
  },
  {
    first_name: "Maria",
    last_name: "Garcia",
    email: "maria.garcia@email.com",
    phone: "+91 87654 32109",
    position: "Operations Coordinator",
    department: "Operations",
    experience: "3 years",
    location: "Kolkata",
    status: "screening",
    applied_date: Date.current - 9.days,
    last_contact: Date.current - 2.days,
    resume: "maria_garcia_resume.pdf",
    cover_letter: "maria_garcia_cover.pdf",
    notes: "Process improvement specialist",
    skills: "Operations Management, Process Improvement, Project Management, Data Analysis",
    education: "BBA Operations",
    current_company: "Manufacturing Company",
    expected_salary: "₹5,50,000",
    availability: "3 weeks notice"
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
  },
  {
    candidate: Candidate.find_by(email: "michael.rodriguez@email.com"),
    interviewer: "Jane Smith",
    interview_type: "video",
    scheduled_date: Date.current + 1.day,
    scheduled_time: Time.parse("15:00"),
    status: "scheduled",
    notes: "Marketing strategy and campaign planning discussion"
  },
  {
    candidate: Candidate.find_by(email: "jennifer.kim@email.com"),
    interviewer: "Sarah Miller",
    interview_type: "video",
    scheduled_date: Date.current + 4.days,
    scheduled_time: Time.parse("11:00"),
    status: "scheduled",
    notes: "HR policies and employee relations case study"
  },
  {
    candidate: Candidate.find_by(email: "robert.johnson@email.com"),
    interviewer: "Tom Anderson",
    interview_type: "onsite",
    scheduled_date: Date.current + 3.days,
    scheduled_time: Time.parse("16:00"),
    status: "scheduled",
    notes: "Financial modeling and analysis test"
  },
  {
    candidate: Candidate.find_by(email: "amanda.davis@email.com"),
    interviewer: "Mark Taylor",
    interview_type: "video",
    scheduled_date: Date.current + 1.day,
    scheduled_time: Time.parse("10:30"),
    status: "scheduled",
    notes: "Sales process and CRM experience assessment"
  },
  {
    candidate: Candidate.find_by(email: "kevin.park@email.com"),
    interviewer: "Bob Wilson",
    interview_type: "video",
    scheduled_date: Date.current + 5.days,
    scheduled_time: Time.parse("14:30"),
    status: "scheduled",
    notes: "DevOps architecture and cloud infrastructure discussion"
  },
  {
    candidate: Candidate.find_by(email: "maria.garcia@email.com"),
    interviewer: "Chris Lopez",
    interview_type: "video",
    scheduled_date: Date.current + 2.days,
    scheduled_time: Time.parse("13:00"),
    status: "scheduled",
    notes: "Operations process improvement and project management"
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
  # Engineering Department Assets
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
    name: "MacBook Air M2",
    asset_type: "laptop",
    serial_number: "MBA2024002",
    model: "MacBook Air 13-inch M2",
    brand: "Apple",
    purchase_date: Date.current - 4.months,
    warranty_expiry: Date.current + 1.year + 8.months,
    purchase_cost: 1299.00,
    current_value: 1150.00,
    status: "assigned",
    location: "Engineering Department",
    department: "Engineering",
    notes: "Assigned to software engineer",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "alice.johnson@company.com").id
  },
  {
    name: "Dell XPS 15",
    asset_type: "laptop",
    serial_number: "DXP2024003",
    model: "XPS 15 9520",
    brand: "Dell",
    purchase_date: Date.current - 5.months,
    warranty_expiry: Date.current + 1.year + 7.months,
    purchase_cost: 1899.00,
    current_value: 1700.00,
    status: "assigned",
    location: "Engineering Department",
    department: "Engineering",
    notes: "Assigned to tech lead",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "bob.wilson@company.com").id
  },
  {
    name: "ThinkPad X1 Carbon",
    asset_type: "laptop",
    serial_number: "TPX2024004",
    model: "ThinkPad X1 Carbon Gen 10",
    brand: "Lenovo",
    purchase_date: Date.current - 3.months,
    warranty_expiry: Date.current + 1.year + 9.months,
    purchase_cost: 1599.00,
    current_value: 1400.00,
    status: "assigned",
    location: "Engineering Department",
    department: "Engineering",
    notes: "Assigned to DevOps engineer",
    condition: "excellent",
    last_maintenance: Date.current - 2.weeks,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "carol.brown@company.com").id
  },

  # Marketing Department Assets
  {
    name: "MacBook Pro 14-inch",
    asset_type: "laptop",
    serial_number: "MBP2024005",
    model: "MacBook Pro 14-inch M2",
    brand: "Apple",
    purchase_date: Date.current - 4.months,
    warranty_expiry: Date.current + 1.year + 8.months,
    purchase_cost: 1999.00,
    current_value: 1800.00,
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
    name: "iPad Pro 12.9-inch",
    asset_type: "mobile",
    serial_number: "IPP2024006",
    model: "iPad Pro 12.9-inch M2",
    brand: "Apple",
    purchase_date: Date.current - 2.months,
    warranty_expiry: Date.current + 1.year + 10.months,
    purchase_cost: 1099.00,
    current_value: 1000.00,
    status: "assigned",
    location: "Marketing Department",
    department: "Marketing",
    notes: "Assigned to content writer",
    condition: "excellent",
    last_maintenance: Date.current - 1.week,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "david.lee@company.com").id
  },

  # HR Department Assets
  {
    name: "HP LaserJet Pro",
    asset_type: "printer",
    serial_number: "HPL2024007",
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
    name: "Dell OptiPlex Desktop",
    asset_type: "desktop",
    serial_number: "DOP2024008",
    model: "OptiPlex 7010",
    brand: "Dell",
    purchase_date: Date.current - 6.months,
    warranty_expiry: Date.current + 1.year + 6.months,
    purchase_cost: 799.00,
    current_value: 650.00,
    status: "assigned",
    location: "HR Department",
    department: "HR",
    notes: "Assigned to HR specialist",
    condition: "good",
    last_maintenance: Date.current - 2.months,
    next_maintenance: Date.current + 4.months,
    employee_id: Employee.find_by(email: "mike.johnson@company.com").id
  },

  # Finance Department Assets
  {
    name: "Dell OptiPlex Desktop",
    asset_type: "desktop",
    serial_number: "DOP2024009",
    model: "OptiPlex 7010",
    brand: "Dell",
    purchase_date: Date.current - 8.months,
    warranty_expiry: Date.current + 1.year + 4.months,
    purchase_cost: 799.00,
    current_value: 650.00,
    status: "assigned",
    location: "Finance Department",
    department: "Finance",
    notes: "Assigned to finance manager",
    condition: "good",
    last_maintenance: Date.current - 4.months,
    next_maintenance: Date.current + 2.months,
    employee_id: Employee.find_by(email: "tom.anderson@company.com").id
  },
  {
    name: "HP EliteBook",
    asset_type: "laptop",
    serial_number: "HPE2024010",
    model: "EliteBook 850 G9",
    brand: "HP",
    purchase_date: Date.current - 3.months,
    warranty_expiry: Date.current + 1.year + 9.months,
    purchase_cost: 1299.00,
    current_value: 1150.00,
    status: "assigned",
    location: "Finance Department",
    department: "Finance",
    notes: "Assigned to accountant",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "lisa.garcia@company.com").id
  },

  # Sales Department Assets
  {
    name: "iPhone 15 Pro",
    asset_type: "mobile",
    serial_number: "IPH2024011",
    model: "iPhone 15 Pro 256GB",
    brand: "Apple",
    purchase_date: Date.current - 3.months,
    warranty_expiry: Date.current + 1.year + 9.months,
    purchase_cost: 1199.00,
    current_value: 1100.00,
    status: "assigned",
    location: "Sales Department",
    department: "Sales",
    notes: "Assigned to sales manager",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "mark.taylor@company.com").id
  },
  {
    name: "Samsung Galaxy S24",
    asset_type: "mobile",
    serial_number: "SGS2024012",
    model: "Galaxy S24 256GB",
    brand: "Samsung",
    purchase_date: Date.current - 2.months,
    warranty_expiry: Date.current + 1.year + 10.months,
    purchase_cost: 999.00,
    current_value: 900.00,
    status: "assigned",
    location: "Sales Department",
    department: "Sales",
    notes: "Assigned to sales executive",
    condition: "excellent",
    last_maintenance: Date.current - 2.weeks,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "rachel.white@company.com").id
  },

  # Design Department Assets
  {
    name: "MacBook Pro 16-inch",
    asset_type: "laptop",
    serial_number: "MBP2024013",
    model: "MacBook Pro 16-inch M2",
    brand: "Apple",
    purchase_date: Date.current - 4.months,
    warranty_expiry: Date.current + 1.year + 8.months,
    purchase_cost: 2499.00,
    current_value: 2200.00,
    status: "assigned",
    location: "Design Department",
    department: "Design",
    notes: "Assigned to UI/UX designer",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months,
    employee_id: Employee.find_by(email: "amy.rodriguez@company.com").id
  },
  {
    name: "Wacom Cintiq 22",
    asset_type: "other",
    serial_number: "WAC2024014",
    model: "Cintiq 22",
    brand: "Wacom",
    purchase_date: Date.current - 5.months,
    warranty_expiry: Date.current + 1.year + 7.months,
    purchase_cost: 1199.00,
    current_value: 1000.00,
    status: "assigned",
    location: "Design Department",
    department: "Design",
    notes: "Assigned to UI/UX designer",
    condition: "excellent",
    last_maintenance: Date.current - 2.months,
    next_maintenance: Date.current + 4.months,
    employee_id: Employee.find_by(email: "amy.rodriguez@company.com").id
  },

  # Operations Department Assets
  {
    name: "Dell Latitude",
    asset_type: "laptop",
    serial_number: "DLT2024015",
    model: "Latitude 7420",
    brand: "Dell",
    purchase_date: Date.current - 7.months,
    warranty_expiry: Date.current + 1.year + 5.months,
    purchase_cost: 1399.00,
    current_value: 1200.00,
    status: "assigned",
    location: "Operations Department",
    department: "Operations",
    notes: "Assigned to operations manager",
    condition: "good",
    last_maintenance: Date.current - 3.months,
    next_maintenance: Date.current + 3.months,
    employee_id: Employee.find_by(email: "chris.lopez@company.com").id
  },

  # Network Infrastructure
  {
    name: "Cisco Switch",
    asset_type: "network",
    serial_number: "CIS2024016",
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
    name: "Ubiquiti Access Point",
    asset_type: "network",
    serial_number: "UAP2024017",
    model: "UniFi AP AC Pro",
    brand: "Ubiquiti",
    purchase_date: Date.current - 6.months,
    warranty_expiry: Date.current + 1.year + 6.months,
    purchase_cost: 149.00,
    current_value: 120.00,
    status: "available",
    location: "Office Floor 1",
    department: "IT",
    notes: "WiFi access point",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months
  },
  {
    name: "Ubiquiti Access Point",
    asset_type: "network",
    serial_number: "UAP2024018",
    model: "UniFi AP AC Pro",
    brand: "Ubiquiti",
    purchase_date: Date.current - 6.months,
    warranty_expiry: Date.current + 1.year + 6.months,
    purchase_cost: 149.00,
    current_value: 120.00,
    status: "available",
    location: "Office Floor 2",
    department: "IT",
    notes: "WiFi access point",
    condition: "excellent",
    last_maintenance: Date.current - 1.month,
    next_maintenance: Date.current + 5.months
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
    asset: Asset.find_by(serial_number: "DXP2024003"),
    maintenance_date: Date.current - 1.month,
    maintenance_type: "repair",
    description: "Paper feed mechanism repair",
    cost: 150.00,
    performed_by: "External Vendor"
  },
  {
    asset: Asset.find_by(serial_number: "DXP2024003"),
    maintenance_date: Date.current - 2.months,
    maintenance_type: "routine",
    description: "Firmware update and security patches",
    cost: 0.00,
    performed_by: "Network Team"
  },
  {
    asset: Asset.find_by(serial_number: "DXP2024003"),
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

# Workspace seating, project management, expenses, and document signatures
puts "Seeding workspace seating, projects, expenses, and policy signatures..."

seat_assignments = {
  "N-01" => Employee.find_by(email: "john.doe@company.com"),
  "N-03" => Employee.find_by(email: "alice.johnson@company.com"),
  "C-08" => Employee.find_by(email: "mike.johnson@company.com"),
  "C-10" => Employee.find_by(email: "sarah.miller@company.com"),
  "S-02" => Employee.find_by(email: "jane.smith@company.com"),
  "S-06" => Employee.find_by(email: "david.lee@company.com")
}
blocked_seat_labels = %w[N-12 C-01 S-29]

if WorkspaceSeat.none?
  { "north" => "N", "center" => "C", "south" => "S" }.each do |zone, prefix|
    30.times do |i|
      label = "#{prefix}-#{format('%02d', i + 1)}"
      employee = seat_assignments[label]
      status = if blocked_seat_labels.include?(label)
        "blocked"
      elsif employee
        "occupied"
      else
        "vacant"
      end

      WorkspaceSeat.find_or_create_by!(label: label) do |seat|
        seat.zone = zone
        seat.status = status
        seat.employee = employee
      end
    end
  end
end

john = Employee.find_by(email: "john.doe@company.com")
alice = Employee.find_by(email: "alice.johnson@company.com")
bob = Employee.find_by(email: "bob.wilson@company.com")
jane = Employee.find_by(email: "jane.smith@company.com")
david = Employee.find_by(email: "david.lee@company.com")
sarah = Employee.find_by(email: "sarah.miller@company.com")

project_seeds = [
  {
    name: "BevyHR Mobile App",
    description: "Mobile application for employee self-service with attendance, leave, and payroll access",
    status: "active",
    progress: 75,
    priority: "high",
    start_date: Date.new(2024, 1, 15),
    end_date: Date.new(2024, 3, 30),
    budget: 50_000,
    spent: 37_500,
    tasks: [
      { title: "Setup development environment", status: "completed", priority: "high", assignee_name: "John Doe", employee: john, due_date: Date.new(2024, 1, 18), story_points: 3, sprint_name: "Sprint 1 - Foundation" },
      { title: "Design user interface mockups", status: "completed", priority: "high", assignee_name: "Jane Smith", employee: jane, due_date: Date.new(2024, 2, 10), story_points: 5, sprint_name: "Sprint 1 - Foundation" },
      { title: "Implement authentication system", status: "in_progress", priority: "high", assignee_name: "Bob Wilson", employee: bob, due_date: Date.new(2024, 2, 28), story_points: 8, sprint_name: "Sprint 2 - Core Features" },
      { title: "Create user dashboard", status: "in_progress", priority: "medium", assignee_name: "Alice Johnson", employee: alice, due_date: Date.new(2024, 3, 5), story_points: 5, sprint_name: "Sprint 2 - Core Features" },
      { title: "Implement attendance tracking", status: "todo", priority: "medium", assignee_name: "Alice Johnson", employee: alice, due_date: Date.new(2024, 3, 10), story_points: 5, sprint_name: "Sprint 3 - HR Modules" },
      { title: "Integrate payroll system", status: "backlog", priority: "high", assignee_name: "Bob Wilson", employee: bob, due_date: Date.new(2024, 3, 18), story_points: 8, sprint_name: "Sprint 3 - HR Modules" }
    ]
  },
  {
    name: "Payroll System Upgrade",
    description: "Modernizing the existing payroll processing system",
    status: "planning",
    progress: 25,
    priority: "medium",
    start_date: Date.new(2024, 2, 1),
    end_date: Date.new(2024, 5, 15),
    budget: 75_000,
    spent: 12_000,
    tasks: [
      { title: "Requirements gathering", status: "completed", priority: "high", assignee_name: "Sarah Miller", employee: sarah, due_date: Date.new(2024, 2, 15), story_points: 5, sprint_name: "Sprint 1 - Discovery" },
      { title: "Payroll calculation engine refactor", status: "in_progress", priority: "high", assignee_name: "Mike Johnson", employee: Employee.find_by(email: "mike.johnson@company.com"), due_date: Date.new(2024, 4, 1), story_points: 13, sprint_name: "Sprint 2 - Engine" },
      { title: "Payslip PDF generation", status: "backlog", priority: "medium", assignee_name: "John Doe", employee: john, due_date: Date.new(2024, 4, 20), story_points: 5, sprint_name: "Sprint 3 - Output" }
    ]
  },
  {
    name: "Performance Analytics Dashboard",
    description: "Real-time analytics for employee performance tracking",
    status: "completed",
    progress: 100,
    priority: "high",
    start_date: Date.new(2023, 11, 1),
    end_date: Date.new(2024, 1, 31),
    budget: 30_000,
    spent: 28_500,
    tasks: [
      { title: "Dashboard wireframes", status: "completed", priority: "medium", assignee_name: "Jane Smith", employee: jane, due_date: Date.new(2023, 11, 20), story_points: 3, sprint_name: "Sprint 1" },
      { title: "Metrics API endpoints", status: "completed", priority: "high", assignee_name: "John Doe", employee: john, due_date: Date.new(2023, 12, 15), story_points: 8, sprint_name: "Sprint 2" },
      { title: "Chart components", status: "completed", priority: "medium", assignee_name: "Alice Johnson", employee: alice, due_date: Date.new(2024, 1, 10), story_points: 5, sprint_name: "Sprint 3" }
    ]
  }
]

project_seeds.each do |project_attrs|
  tasks = project_attrs.delete(:tasks)
  project = Project.find_or_create_by!(name: project_attrs[:name]) do |p|
    p.assign_attributes(project_attrs)
  end

  tasks.each do |task_attrs|
    ProjectTask.find_or_create_by!(project: project, title: task_attrs[:title]) do |task|
      task.assign_attributes(task_attrs)
    end
  end
end

expense_seeds = [
  {
    employee: john,
    title: "Office Supplies",
    amount: 125.50,
    category: "Office",
    expense_date: Date.current - 15.days,
    description: "Pens, notebooks, and stationery",
    payment_method: "Credit Card",
    tags: %w[work supplies],
    status: "approved"
  },
  {
    employee: jane,
    title: "Lunch Meeting",
    amount: 45.00,
    category: "Meals",
    expense_date: Date.current - 14.days,
    description: "Client lunch at restaurant",
    payment_method: "Cash",
    tags: %w[business client],
    status: "submitted"
  },
  {
    employee: alice,
    title: "Uber Ride",
    amount: 18.75,
    category: "Transportation",
    expense_date: Date.current - 13.days,
    description: "Ride to client office",
    payment_method: "Credit Card",
    tags: %w[transport business],
    status: "approved"
  },
  {
    employee: bob,
    title: "Software License",
    amount: 299.00,
    category: "Software",
    expense_date: Date.current - 12.days,
    description: "Annual subscription for design software",
    payment_method: "Bank Transfer",
    tags: %w[software subscription],
    status: "reimbursed"
  },
  {
    employee: david,
    title: "Team Coffee",
    amount: 24.50,
    category: "Meals",
    expense_date: Date.current - 11.days,
    description: "Morning coffee for marketing standup",
    payment_method: "Credit Card",
    tags: %w[coffee team],
    status: "submitted"
  }
]

expense_seeds.each do |expense_attrs|
  Expense.find_or_create_by!(
    employee: expense_attrs[:employee],
    title: expense_attrs[:title],
    expense_date: expense_attrs[:expense_date]
  ) do |expense|
    expense.assign_attributes(expense_attrs)
  end
end

admin_user = User.find_by(email: "admin@hrms.com")
policy_seeds = [
  {
    title: "Employee Handbook 2024",
    category: "HR Policies",
    version: "v2.1",
    file_path: "policy-documents/employee-handbook-2024.pdf",
    file_size: 2_516_582,
    last_updated: Date.current - 2.months,
    expiry_date: Date.current + 10.months,
    status: "active",
    downloads: 156,
    requires_signature: true,
    uploaded_by: admin_user&.id
  },
  {
    title: "Code of Conduct",
    category: "Compliance",
    version: "v1.5",
    file_path: "policy-documents/code-of-conduct.pdf",
    file_size: 1_887_436,
    last_updated: Date.current - 3.months,
    expiry_date: Date.current + 9.months,
    status: "active",
    downloads: 203,
    requires_signature: true,
    uploaded_by: admin_user&.id
  },
  {
    title: "Leave Policy",
    category: "HR Policies",
    version: "v1.2",
    file_path: "policy-documents/leave-policy.pdf",
    file_size: 1_572_864,
    last_updated: Date.current - 8.months,
    expiry_date: Date.current + 20.days,
    status: "expiring",
    downloads: 134,
    requires_signature: false,
    uploaded_by: admin_user&.id
  }
]

policy_seeds.each do |policy_attrs|
  PolicyDocument.find_or_create_by!(title: policy_attrs[:title]) do |doc|
    doc.assign_attributes(policy_attrs)
  end
end

handbook = PolicyDocument.find_by(title: "Employee Handbook 2024")
conduct = PolicyDocument.find_by(title: "Code of Conduct")

if handbook && john
  DigitalSignature.find_or_create_by!(policy_document: handbook, employee: john) do |sig|
    sig.status = "signed"
    sig.signed_date = Date.current - 1.month
    sig.signature_type = "electronic"
    sig.ip_address = "192.168.1.100"
    sig.device_info = "Chrome on Mac"
  end
end

if conduct && jane
  DigitalSignature.find_or_create_by!(policy_document: conduct, employee: jane) do |sig|
    sig.status = "pending"
    sig.signature_type = "pending"
  end
end

if conduct && alice
  DigitalSignature.find_or_create_by!(policy_document: conduct, employee: alice) do |sig|
    sig.status = "signed"
    sig.signed_date = Date.current - 3.weeks
    sig.signature_type = "electronic"
    sig.ip_address = "192.168.1.105"
    sig.device_info = "Safari on Mac"
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
    employee: Employee.find_by(email: "john.doe@company.com"),
    last_working_day: Date.current + 5.days,
    status: "in_progress",
    progress: 65,
    assigned_to: "Mike Chen",
    notes: "Moving to another company",
    start_date: Date.current - 10.days
  },
  {
    employee: Employee.find_by(email: "jane.smith@company.com"),
    last_working_day: Date.current + 15.days,
    status: "pending",
    progress: 0,
    assigned_to: "Lisa Wang",
    notes: "Personal reasons",
    start_date: Date.current - 2.days
  },
  {
    employee: Employee.find_by(email: "mike.johnson@company.com"),
    last_working_day: Date.current - 5.days,
    status: "completed",
    progress: 100,
    assigned_to: "John Smith",
    notes: "Completed successfully",
    start_date: Date.current - 20.days
  }
]

offboarding_employees.each do |offboarding_data|
  offboarding_employee = OffboardingEmployee.find_or_create_by!(employee: offboarding_data[:employee]) do |oe|
    oe.assign_attributes(offboarding_data.except(:employee))
  end

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
puts "Created #{SalaryStructure.count} salary structures"
puts "Created #{Payroll.count} payroll records"
puts "Created #{AttendanceRecord.count} attendance records"
puts "Created #{JobOpening.count} job openings"
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
puts "Created #{WorkspaceSeat.count} workspace seats"
puts "Created #{Project.count} projects with #{ProjectTask.count} tasks"
puts "Created #{Expense.count} expenses"
puts "Created #{PolicyDocument.count} policy documents"
puts "Created #{DigitalSignature.count} digital signatures"
puts "Created #{LeaveRequest.count} leave requests"

# Create Helpdesk Tickets
puts "Creating helpdesk tickets..."
if Employee.count > 0
  hr_dept = Department.find_by(name: "HR")
  hr_employees = hr_dept ? hr_dept.employees : Employee.limit(3)

  helpdesk_tickets = [
    {
      title: "Payroll Query - Missing Overtime",
      description: "Employee reports missing overtime hours in last month's payroll. Need to verify and process the correction.",
      category: "Payroll",
      priority: "high",
      status: "open",
      assigned_to_id: hr_employees.first&.id,
      requester_id: Employee.where.not(id: hr_employees.map(&:id)).first&.id,
      sla_hours: 24,
      sla_status: "on-track",
      channel: "email",
      tags: "payroll,overtime,urgent"
    },
    {
      title: "Benefits Enrollment Issue",
      description: "Unable to enroll in new health insurance plan through portal. Getting error message when submitting enrollment form.",
      category: "Benefits",
      priority: "medium",
      status: "in-progress",
      assigned_to_id: hr_employees.second&.id,
      requester_id: Employee.where.not(id: hr_employees.map(&:id)).second&.id,
      sla_hours: 48,
      sla_status: "on-track",
      channel: "portal",
      tags: "benefits,enrollment,portal"
    },
    {
      title: "Leave Request Approval",
      description: "Pending approval for 2 weeks vacation in March. Request submitted 5 days ago but still showing as pending.",
      category: "Leave Management",
      priority: "low",
      status: "pending",
      assigned_to_id: hr_employees.first&.id,
      requester_id: Employee.where.not(id: hr_employees.map(&:id)).third&.id,
      sla_hours: 72,
      sla_status: "on-track",
      channel: "system",
      tags: "leave,approval,vacation"
    },
    {
      title: "Performance Review Query",
      description: "Questions about the performance review process and timeline for Q4 reviews.",
      category: "Performance",
      priority: "medium",
      status: "open",
      assigned_to_id: hr_employees.first&.id,
      requester_id: Employee.where.not(id: hr_employees.map(&:id)).fourth&.id,
      sla_hours: 48,
      sla_status: "on-track",
      channel: "email",
      tags: "performance,review"
    },
    {
      title: "IT Access Request",
      description: "Need access to new project management tool and development environment.",
      category: "IT Support",
      priority: "high",
      status: "resolved",
      assigned_to_id: hr_employees.first&.id,
      requester_id: Employee.where.not(id: hr_employees.map(&:id)).fifth&.id,
      sla_hours: 24,
      sla_status: "on-track",
      channel: "portal",
      tags: "it,access,request"
    }
  ]

  helpdesk_tickets.each do |ticket_data|
    HelpdeskTicket.find_or_create_by!(title: ticket_data[:title]) do |ticket|
      ticket.assign_attributes(ticket_data)
      ticket.created_at = rand(1..10).days.ago
    end
  end
end

# Create SLA Workflows
puts "Creating SLA workflows..."
sla_workflows = [
  {
    name: "Payroll Issues",
    category: "Payroll",
    priority: "high",
    sla_hours: 24,
    status: "active",
    tickets_handled: 45,
    avg_resolution_hours: 18.5,
    escalation_levels: [
      { level: 1, time: "4h", action: "Initial Response" },
      { level: 2, time: "12h", action: "Escalate to Specialist" },
      { level: 3, time: "24h", action: "Escalate to Manager" }
    ].to_json
  },
  {
    name: "Benefits & Enrollment",
    category: "Benefits",
    priority: "medium",
    sla_hours: 48,
    status: "active",
    tickets_handled: 32,
    avg_resolution_hours: 36.0,
    escalation_levels: [
      { level: 1, time: "8h", action: "Initial Response" },
      { level: 2, time: "24h", action: "Escalate to Benefits Team" },
      { level: 3, time: "48h", action: "Escalate to Manager" }
    ].to_json
  },
  {
    name: "Leave Management",
    category: "Leave Management",
    priority: "low",
    sla_hours: 72,
    status: "active",
    tickets_handled: 28,
    avg_resolution_hours: 48.0,
    escalation_levels: [
      { level: 1, time: "12h", action: "Initial Response" },
      { level: 2, time: "48h", action: "Escalate to HR Manager" },
      { level: 3, time: "72h", action: "Escalate to Director" }
    ].to_json
  },
  {
    name: "IT Support Requests",
    category: "IT Support",
    priority: "high",
    sla_hours: 24,
    status: "active",
    tickets_handled: 67,
    avg_resolution_hours: 16.0,
    escalation_levels: [
      { level: 1, time: "2h", action: "Initial Response" },
      { level: 2, time: "8h", action: "Escalate to IT Team Lead" },
      { level: 3, time: "24h", action: "Escalate to IT Manager" }
    ].to_json
  }
]

sla_workflows.each do |workflow_data|
  SlaWorkflow.find_or_create_by!(name: workflow_data[:name]) do |workflow|
    workflow.assign_attributes(workflow_data)
  end
end

# Create Knowledge Articles
puts "Creating knowledge articles..."
knowledge_articles = [
  {
    title: "How to Submit a Leave Request",
    content: "Step-by-step guide for submitting leave requests through the HR portal:\n\n1. Log in to the HR portal\n2. Navigate to the Leave Management section\n3. Click on 'Request Leave'\n4. Select the leave type (Sick, Vacation, Personal, etc.)\n5. Choose your start and end dates\n6. Add any comments or notes\n7. Submit your request\n\nYour manager will be notified automatically and you'll receive updates via email.",
    category: "Leave Management",
    author: "HR Team",
    tags: "leave,request,portal,guide",
    views: 156,
    helpful: 23,
    status: "published",
    last_updated: 15.days.ago
  },
  {
    title: "Payroll Schedule and Payment Methods",
    content: "Information about payroll processing dates, payment methods, and direct deposit setup:\n\nPayroll Schedule:\n- Payroll is processed on the 25th of each month\n- Payments are disbursed on the 1st of the following month\n- For months with holidays, payments are processed one business day earlier\n\nPayment Methods:\n- Direct Deposit (recommended): Set up through the employee portal\n- Bank Transfer: Automatic transfer to your registered bank account\n- Check: Available upon request (may take additional 2-3 business days)\n\nTo set up direct deposit, go to Payroll > Payment Methods in your employee portal.",
    category: "Payroll",
    author: "Payroll Team",
    tags: "payroll,schedule,payment,direct-deposit",
    views: 234,
    helpful: 45,
    status: "published",
    last_updated: 10.days.ago
  },
  {
    title: "Benefits Enrollment Guide",
    content: "Complete guide to enrolling in employee benefits:\n\nAvailable Benefits:\n- Health Insurance (Medical, Dental, Vision)\n- Life Insurance\n- Retirement Plans (401k)\n- Flexible Spending Accounts (FSA)\n\nEnrollment Periods:\n- New Hire: Within 30 days of joining\n- Annual Open Enrollment: November 1-15\n- Qualifying Life Events: Within 30 days of event\n\nTo enroll:\n1. Access the Benefits Portal\n2. Review available plans\n3. Select your coverage options\n4. Add dependents if applicable\n5. Submit your enrollment\n\nFor questions, contact the Benefits team at benefits@company.com",
    category: "Benefits",
    author: "Benefits Team",
    tags: "benefits,enrollment,insurance,guide",
    views: 189,
    helpful: 34,
    status: "published",
    last_updated: 7.days.ago
  },
  {
    title: "Performance Review Process",
    content: "Understanding the performance review cycle:\n\nReview Schedule:\n- Annual Reviews: Conducted in December\n- Mid-Year Check-ins: Conducted in June\n- Quarterly Goals: Reviewed each quarter\n\nProcess:\n1. Self-Assessment: Complete your self-evaluation\n2. Manager Review: Your manager reviews and provides feedback\n3. Goal Setting: Set goals for the next period\n4. Development Plan: Create a professional development plan\n\nPerformance Ratings:\n- Exceeds Expectations\n- Meets Expectations\n- Needs Improvement\n\nAll reviews are documented in the Performance Management system.",
    category: "Performance",
    author: "HR Team",
    tags: "performance,review,goals,feedback",
    views: 142,
    helpful: 28,
    status: "published",
    last_updated: 5.days.ago
  },
  {
    title: "IT Support and Access Requests",
    content: "How to request IT support and system access:\n\nIT Support:\n- Submit tickets through the Helpdesk portal\n- Email: it-support@company.com\n- Phone: Extension 1234\n- Response time: Within 4 hours for urgent issues\n\nAccess Requests:\n- Software Access: Request through the IT portal\n- System Access: Submit access request form\n- Hardware Requests: Contact IT procurement\n\nCommon Requests:\n- Email account setup\n- VPN access\n- Software licenses\n- Hardware (laptops, monitors, etc.)\n- Password resets\n\nFor urgent issues, call the IT helpdesk directly.",
    category: "IT Support",
    author: "IT Team",
    tags: "it,support,access,helpdesk",
    views: 201,
    helpful: 41,
    status: "published",
    last_updated: 3.days.ago
  }
]

knowledge_articles.each do |article_data|
  KnowledgeArticle.find_or_create_by!(title: article_data[:title]) do |article|
    article.assign_attributes(article_data)
  end
end

puts "Created #{HelpdeskTicket.count} helpdesk tickets"
puts "Created #{SlaWorkflow.count} SLA workflows"
puts "Created #{KnowledgeArticle.count} knowledge articles"

# Load user roles and permissions
load Rails.root.join('db', 'seeds', 'users_and_roles.rb')

puts "Creating employee for Super Admin user..."
super_admin_user = User.find_by(email: 'admin@hrms.com')
if super_admin_user && super_admin_user.employee_id.nil?
  hr_department = Department.find_by(name: "HR") || Department.first

  employee = Employee.find_or_create_by!(email: super_admin_user.email) do |emp|
    emp.first_name = super_admin_user.first_name
    emp.last_name = super_admin_user.last_name
    emp.phone = "+91 9876543212"
    emp.department_id = hr_department.id
    emp.designation = "Super Administrator"
    emp.date_of_joining = super_admin_user.created_at.to_date
    emp.status = "active"
  end

  super_admin_user.update!(employee_id: employee.id)
  puts "✓ Created employee for Super Admin user (Employee ID: #{employee.id})"
elsif super_admin_user && super_admin_user.employee_id.present?
  puts "✓ Super Admin user already has an employee record (Employee ID: #{super_admin_user.employee_id})"
elsif super_admin_user.nil?
  puts "⚠ Super Admin user (admin@hrms.com) not found"
end

# Create general channels for chat
puts "Creating general channels..."
if User.count > 0 && Channel.count == 0
  # Get the first user (or super admin) as creator
  creator = super_admin_user || User.first

  # Create general channels
  general_channels = [
    {
      name: "general",
      channel_type: "channel",
      is_private: false,
      description: "General discussions and announcements for everyone",
      created_by: creator
    },
    {
      name: "random",
      channel_type: "channel",
      is_private: false,
      description: "Random conversations and off-topic discussions",
      created_by: creator
    },
    {
      name: "announcements",
      channel_type: "channel",
      is_private: false,
      description: "Company-wide announcements and important updates",
      created_by: creator
    },
    {
      name: "engineering",
      channel_type: "channel",
      is_private: false,
      description: "Engineering team discussions",
      created_by: creator
    },
    {
      name: "marketing",
      channel_type: "channel",
      is_private: false,
      description: "Marketing team discussions",
      created_by: creator
    },
    {
      name: "hr",
      channel_type: "channel",
      is_private: false,
      description: "HR team discussions",
      created_by: creator
    }
  ]

  general_channels.each do |channel_data|
    channel = Channel.find_or_create_by!(name: channel_data[:name]) do |ch|
      ch.channel_type = channel_data[:channel_type]
      ch.is_private = channel_data[:is_private]
      ch.description = channel_data[:description]
      ch.created_by = channel_data[:created_by]
    end

    # Add all active users as members
    User.active.each do |user|
      ChannelMembership.find_or_create_by!(channel: channel, user: user) do |membership|
        membership.role = user == creator ? "admin" : "member"
      end
    end

    # Add some welcome messages to general channel
    if channel.name == "general"
      welcome_messages = [
        {
          content: "Welcome to the general channel! This is where we share company-wide updates and have open discussions.",
          user: creator,
          created_at: 2.days.ago
        },
        {
          content: "Feel free to introduce yourself and let everyone know what you're working on!",
          user: creator,
          created_at: 2.days.ago + 1.hour
        }
      ]

      welcome_messages.each do |msg_data|
        # Check if message already exists
        existing_msg = Message.where(
          channel: channel,
          user: msg_data[:user],
          content: msg_data[:content]
        ).first

        unless existing_msg
          Message.create!(
            channel: channel,
            user: msg_data[:user],
            content: msg_data[:content],
            created_at: msg_data[:created_at]
          )
        end
      end
    end

    # Add a welcome message to announcements channel
    if channel.name == "announcements"
      existing_announcement = Message.where(
        channel: channel,
        user: creator,
        content: "Welcome to the announcements channel! Important company updates will be posted here."
      ).first

      unless existing_announcement
        Message.create!(
          channel: channel,
          user: creator,
          content: "Welcome to the announcements channel! Important company updates will be posted here.",
          created_at: 1.day.ago
        )
      end
    end

    puts "✓ Created channel: #{channel.name}"
  end

  puts "Created #{Channel.count} channels"
  puts "Created #{ChannelMembership.count} channel memberships"
  puts "Created #{Message.count} messages"
else
  puts "Channels already exist or no users found. Skipping channel creation."
end

# Create general channels for chat
puts "Creating general channels..."
if User.count > 0 && Channel.count == 0
  # Get the first user (or super admin) as creator
  creator = super_admin_user || User.first

  # Create general channels
  general_channels = [
    {
      name: "general",
      channel_type: "channel",
      is_private: false,
      description: "General discussions and announcements for everyone",
      created_by: creator
    },
    {
      name: "random",
      channel_type: "channel",
      is_private: false,
      description: "Random conversations and off-topic discussions",
      created_by: creator
    },
    {
      name: "announcements",
      channel_type: "channel",
      is_private: false,
      description: "Company-wide announcements and important updates",
      created_by: creator
    },
    {
      name: "engineering",
      channel_type: "channel",
      is_private: false,
      description: "Engineering team discussions",
      created_by: creator
    },
    {
      name: "marketing",
      channel_type: "channel",
      is_private: false,
      description: "Marketing team discussions",
      created_by: creator
    },
    {
      name: "hr",
      channel_type: "channel",
      is_private: false,
      description: "HR team discussions",
      created_by: creator
    }
  ]

  general_channels.each do |channel_data|
    channel = Channel.find_or_create_by!(name: channel_data[:name]) do |ch|
      ch.channel_type = channel_data[:channel_type]
      ch.is_private = channel_data[:is_private]
      ch.description = channel_data[:description]
      ch.created_by = channel_data[:created_by]
    end

    # Add all active users as members
    User.active.each do |user|
      ChannelMembership.find_or_create_by!(channel: channel, user: user) do |membership|
        membership.role = user == creator ? "admin" : "member"
      end
    end

    # Add some welcome messages to general channel
    if channel.name == "general"
      welcome_messages = [
        {
          content: "Welcome to the general channel! This is where we share company-wide updates and have open discussions.",
          user: creator,
          created_at: 2.days.ago
        },
        {
          content: "Feel free to introduce yourself and let everyone know what you're working on!",
          user: creator,
          created_at: 2.days.ago + 1.hour
        }
      ]

      welcome_messages.each do |msg_data|
        Message.find_or_create_by!(
          channel: channel,
          user: msg_data[:user],
          content: msg_data[:content],
          created_at: msg_data[:created_at]
        )
      end
    end

    # Add a welcome message to announcements channel
    if channel.name == "announcements"
      Message.find_or_create_by!(
        channel: channel,
        user: creator,
        content: "Welcome to the announcements channel! Important company updates will be posted here.",
        created_at: 1.day.ago
      )
    end

    puts "✓ Created channel: #{channel.name}"
  end

  puts "Created #{Channel.count} channels"
  puts "Created #{ChannelMembership.count} channel memberships"
  puts "Created #{Message.count} messages"
else
  puts "Channels already exist or no users found. Skipping channel creation."
end
end # ActsAsTenant.with_tenant

load Rails.root.join("db", "seeds", "platform_admin.rb")
load Rails.root.join("db", "seeds", "platform_saas.rb")
