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
Employee.all.each do |employee|
  # Create attendance records for the last 30 days
  (0..29).each do |day_offset|
    date = Date.current - day_offset.days
    next if date.saturday? || date.sunday? # Skip weekends
    
    AttendanceRecord.find_or_create_by!(
      employee: employee,
      date: date
    ) do |attendance|
      attendance.check_in = Time.parse("09:00") + rand(0..30).minutes
      attendance.check_out = Time.parse("18:00") + rand(-30..30).minutes
      attendance.status = ["present", "late", "early_departure"].sample
    end
  end
end

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
    name: "Sarah Wilson",
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
    name: "David Brown",
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
    name: "Lisa Chen",
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
    name: "Michael Rodriguez",
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
    name: "Jennifer Kim",
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
    name: "Robert Johnson",
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
    name: "Amanda Davis",
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
    name: "Kevin Park",
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
    name: "Maria Garcia",
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
puts "Created #{LeaveRequest.count} leave requests"

# Load user roles and permissions
load Rails.root.join('db', 'seeds', 'users_and_roles.rb')