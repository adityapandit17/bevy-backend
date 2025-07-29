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
      is_completed: oe.status == "in_progress",
      documents: "Employment Contract,Tax Forms,Emergency Contact"
    },
    {
      title: "IT Setup",
      description: "Configure laptop, email, and access to company systems",
      category: "IT",
      priority: "high",
      due_date: oe.start_date - 3.days,
      assigned_to: "IT Team",
      is_completed: oe.status == "in_progress"
    },
    {
      title: "Department Orientation",
      description: "Meet with team lead and understand team processes",
      category: "Department",
      priority: "medium",
      due_date: oe.start_date + 1.day,
      assigned_to: "Team Lead",
      is_completed: false
    },
    {
      title: "Company Policy Training",
      description: "Complete mandatory company policy and compliance training",
      category: "Training",
      priority: "medium",
      due_date: oe.start_date + 3.days,
      assigned_to: "Training Team",
      is_completed: false
    }
  ]

  default_tasks.each do |task_attrs|
    oe.onboarding_tasks.create!(task_attrs)
  end
end

# Create candidates
candidates = [
  {
    name: "Arjun Mehta",
    email: "arjun.mehta@email.com",
    phone: "+91 98765 43210",
    position: "Senior Software Engineer",
    department: "Engineering",
    experience: "5 years",
    location: "Mumbai",
    status: "interview",
    applied_date: Date.current - 7.days,
    last_contact: Date.current - 2.days,
    resume: "arjun_mehta_resume.pdf",
    cover_letter: "arjun_mehta_cover.pdf",
    notes: "Strong technical background, good communication skills. Previous experience with React and Node.js.",
    skills: "React,Node.js,TypeScript,MongoDB,AWS",
    education: "B.Tech Computer Science, IIT Mumbai",
    current_company: "TechCorp India",
    expected_salary: "₹18-22 LPA",
    availability: "Immediate"
  },
  {
    name: "Kavya Nair",
    email: "kavya.nair@email.com",
    phone: "+91 87654 32109",
    position: "Product Manager",
    department: "Product",
    experience: "7 years",
    location: "Bangalore",
    status: "screening",
    applied_date: Date.current - 5.days,
    last_contact: Date.current - 1.day,
    resume: "kavya_nair_resume.pdf",
    notes: "Excellent product sense, strong analytical skills. Previous experience in fintech.",
    skills: "Product Strategy,Data Analysis,User Research,Agile,SQL",
    education: "MBA, IIM Bangalore",
    current_company: "FinTech Solutions",
    expected_salary: "₹25-30 LPA",
    availability: "2 weeks notice"
  },
  {
    name: "Rohit Gupta",
    email: "rohit.gupta@email.com",
    phone: "+91 76543 21098",
    position: "UI/UX Designer",
    department: "Design",
    experience: "3 years",
    location: "Delhi",
    status: "technical",
    applied_date: Date.current - 3.days,
    last_contact: Date.current,
    resume: "rohit_gupta_resume.pdf",
    cover_letter: "rohit_gupta_cover.pdf",
    notes: "Creative designer with strong portfolio. Good understanding of user-centered design.",
    skills: "Figma,Adobe Creative Suite,Prototyping,User Research,Design Systems",
    education: "B.Des, NID Ahmedabad",
    current_company: "Design Studio",
    expected_salary: "₹12-15 LPA",
    availability: "1 week notice"
  }
]

candidates.each do |candidate_attrs|
  Candidate.find_or_create_by!(email: candidate_attrs[:email]) do |candidate|
    candidate.assign_attributes(candidate_attrs)
  end
end

# Create interviews for candidates
interviews = [
  {
    candidate_id: Candidate.find_by(email: "arjun.mehta@email.com").id,
    interview_type: "phone",
    scheduled_date: Date.current - 5.days,
    scheduled_time: Time.parse("10:00"),
    interviewer: "Sarah Johnson",
    status: "completed",
    notes: "Good technical discussion, candidate showed strong problem-solving skills",
    feedback: "Positive - Proceed to technical round",
    rating: 4
  },
  {
    candidate_id: Candidate.find_by(email: "arjun.mehta@email.com").id,
    interview_type: "video",
    scheduled_date: Date.current + 2.days,
    scheduled_time: Time.parse("14:00"),
    interviewer: "Mike Chen",
    status: "scheduled",
    notes: "Technical coding interview"
  },
  {
    candidate_id: Candidate.find_by(email: "rohit.gupta@email.com").id,
    interview_type: "video",
    scheduled_date: Date.current - 2.days,
    scheduled_time: Time.parse("11:00"),
    interviewer: "Lisa Wang",
    status: "completed",
    notes: "Portfolio review and design discussion",
    feedback: "Excellent design skills, good cultural fit",
    rating: 5
  }
]

interviews.each do |interview_attrs|
  Interview.find_or_create_by!(
    candidate_id: interview_attrs[:candidate_id],
    scheduled_date: interview_attrs[:scheduled_date],
    scheduled_time: interview_attrs[:scheduled_time]
  ) do |interview|
    interview.assign_attributes(interview_attrs)
  end
end

puts "Seed data created successfully!"
puts "Created #{Department.count} departments"
puts "Created #{Employee.count} employees"
puts "Created #{OnboardingEmployee.count} onboarding employees"
puts "Created #{OnboardingTask.count} onboarding tasks"
puts "Created #{Candidate.count} candidates"
puts "Created #{Interview.count} interviews"