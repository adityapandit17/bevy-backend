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

ActiveRecord::Schema[8.0].define(version: 2025_09_08_100341) do
  create_table "asset_allocations", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.integer "employee_id", null: false
    t.date "assigned_date"
    t.date "return_date"
    t.text "notes"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_asset_allocations_on_asset_id"
    t.index ["employee_id"], name: "index_asset_allocations_on_employee_id"
  end

  create_table "assets", force: :cascade do |t|
    t.string "name"
    t.string "asset_type"
    t.string "serial_number"
    t.string "model"
    t.string "brand"
    t.date "purchase_date"
    t.date "warranty_expiry"
    t.decimal "purchase_cost"
    t.decimal "current_value"
    t.string "status"
    t.string "location"
    t.string "department"
    t.text "notes"
    t.string "condition"
    t.date "last_maintenance"
    t.date "next_maintenance"
    t.integer "employee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_assets_on_employee_id"
  end

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

  create_table "employee_benefits", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "name"
    t.string "benefit_type"
    t.string "provider"
    t.string "coverage"
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_employee_benefits_on_employee_id"
  end

  create_table "employee_documents", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "name"
    t.string "document_type"
    t.date "upload_date"
    t.date "expiry_date"
    t.string "status"
    t.string "file_size"
    t.string "uploaded_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_employee_documents_on_employee_id"
  end

  create_table "employee_trainings", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "name"
    t.string "training_type"
    t.string "provider"
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.integer "progress"
    t.string "certificate"
    t.decimal "cost"
    t.text "skills"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hours", default: 0
    t.index ["employee_id"], name: "index_employee_trainings_on_employee_id"
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
    t.string "requirements"
    t.string "status"
    t.string "location"
    t.string "job_type"
    t.integer "vacancies"
    t.integer "salary_min"
    t.integer "salary_max"
    t.string "experience"
    t.string "skills"
    t.date "posted"
    t.integer "applications"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_job_openings_on_department_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
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
    t.integer "days"
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
  end

  create_table "maintenance_records", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.date "maintenance_date"
    t.string "maintenance_type"
    t.text "description"
    t.decimal "cost"
    t.string "performed_by"
    t.date "next_maintenance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_maintenance_records_on_asset_id"
  end

  create_table "offboarding_employees", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.date "last_working_day"
    t.string "status"
    t.integer "progress"
    t.string "assigned_to"
    t.text "notes"
    t.date "start_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_offboarding_employees_on_employee_id"
  end

  create_table "offboarding_tasks", force: :cascade do |t|
    t.integer "offboarding_employee_id", null: false
    t.string "title"
    t.text "description"
    t.string "category"
    t.string "priority"
    t.date "due_date"
    t.string "assigned_to"
    t.boolean "is_completed"
    t.date "completed_date"
    t.text "documents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offboarding_employee_id"], name: "index_offboarding_tasks_on_offboarding_employee_id"
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

  create_table "performance_goals", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "title"
    t.text "description"
    t.string "target"
    t.integer "progress"
    t.string "status"
    t.date "due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_performance_goals_on_employee_id"
  end

  create_table "performance_reviews", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "period"
    t.decimal "rating"
    t.string "reviewer"
    t.date "review_date"
    t.text "comments"
    t.text "goals"
    t.text "achievements"
    t.text "areas_for_improvement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_performance_reviews_on_employee_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name", null: false
    t.string "resource", null: false
    t.string "action", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_permissions_on_name", unique: true
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "role_permissions", force: :cascade do |t|
    t.integer "role_id", null: false
    t.integer "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
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

  create_table "timesheets", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.date "date"
    t.decimal "hours"
    t.string "project"
    t.string "task"
    t.string "status"
    t.string "approved_by"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_timesheets_on_employee_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "status", default: "active", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "asset_allocations", "assets"
  add_foreign_key "asset_allocations", "employees"
  add_foreign_key "assets", "employees"
  add_foreign_key "attendance_records", "employees"
  add_foreign_key "employee_benefits", "employees"
  add_foreign_key "employee_documents", "employees"
  add_foreign_key "employee_trainings", "employees"
  add_foreign_key "employees", "departments"
  add_foreign_key "interviews", "candidates"
  add_foreign_key "job_openings", "departments"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "maintenance_records", "assets"
  add_foreign_key "offboarding_employees", "employees"
  add_foreign_key "offboarding_tasks", "offboarding_employees"
  add_foreign_key "onboarding_employees", "employees"
  add_foreign_key "onboarding_tasks", "onboarding_employees"
  add_foreign_key "payrolls", "employees"
  add_foreign_key "performance_goals", "employees"
  add_foreign_key "performance_reviews", "employees"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "salary_structures", "employees"
  add_foreign_key "timesheets", "employees"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
