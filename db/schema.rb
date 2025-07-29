# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_29_202109) do
  create_table "attendance_records", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.date "date"
    t.string "status"
    t.time "check_in"
    t.time "check_out"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_attendance_records_on_employee_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "position"
    t.string "department"
    t.string "experience"
    t.string "location"
    t.string "status"
    t.date "applied_date"
    t.date "last_contact"
    t.string "resume"
    t.string "cover_letter"
    t.text "notes"
    t.text "skills"
    t.string "education"
    t.string "current_company"
    t.string "expected_salary"
    t.string "availability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "industry"
    t.string "employee_count"
    t.text "address"
    t.string "timezone"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employees", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.integer "department_id", null: false
    t.string "designation"
    t.date "date_of_joining"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  create_table "interviews", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.string "interview_type"
    t.date "scheduled_date"
    t.time "scheduled_time"
    t.string "interviewer"
    t.string "status"
    t.text "notes"
    t.text "feedback"
    t.integer "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_interviews_on_candidate_id"
  end

  create_table "job_openings", force: :cascade do |t|
    t.string "title"
    t.integer "department_id", null: false
    t.text "description"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "requirements"
    t.string "location"
    t.string "job_type"
    t.integer "vacancies"
    t.integer "salary_min"
    t.integer "salary_max"
    t.string "experience"
    t.string "skills"
    t.date "posted"
    t.integer "applications"
    t.index ["department_id"], name: "index_job_openings_on_department_id"
  end

  create_table "leave_requests", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "leave_type"
    t.date "start_date"
    t.date "end_date"
    t.text "reason"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
  end

  create_table "onboarding_employees", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.date "start_date"
    t.string "status"
    t.integer "progress"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_onboarding_employees_on_employee_id"
  end

  create_table "onboarding_tasks", force: :cascade do |t|
    t.integer "onboarding_employee_id", null: false
    t.string "title"
    t.text "description"
    t.string "category"
    t.string "priority"
    t.date "due_date"
    t.string "assigned_to"
    t.boolean "is_completed"
    t.text "documents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_employee_id"], name: "index_onboarding_tasks_on_onboarding_employee_id"
  end

  create_table "payrolls", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "month"
    t.decimal "gross_salary"
    t.decimal "net_salary"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
  end

  create_table "salary_structures", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.decimal "basic"
    t.decimal "hra"
    t.decimal "allowances"
    t.decimal "deductions"
    t.date "effective_from"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_salary_structures_on_employee_id"
  end

  add_foreign_key "attendance_records", "employees"
  add_foreign_key "employees", "departments"
  add_foreign_key "interviews", "candidates"
  add_foreign_key "job_openings", "departments"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "onboarding_employees", "employees"
  add_foreign_key "onboarding_tasks", "onboarding_employees"
  add_foreign_key "payrolls", "employees"
  add_foreign_key "salary_structures", "employees"
end
