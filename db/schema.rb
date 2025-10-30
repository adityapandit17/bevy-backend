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

ActiveRecord::Schema[8.1].define(version: 2025_10_30_060443) do
  create_table "asset_allocations", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.date "assigned_date"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.text "notes"
    t.date "return_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_asset_allocations_on_asset_id"
    t.index ["employee_id"], name: "index_asset_allocations_on_employee_id"
  end

  create_table "assets", force: :cascade do |t|
    t.string "asset_type"
    t.string "brand"
    t.string "condition"
    t.datetime "created_at", null: false
    t.decimal "current_value"
    t.string "department"
    t.integer "employee_id"
    t.date "last_maintenance"
    t.string "location"
    t.string "model"
    t.string "name"
    t.date "next_maintenance"
    t.text "notes"
    t.decimal "purchase_cost"
    t.date "purchase_date"
    t.string "serial_number"
    t.string "status"
    t.datetime "updated_at", null: false
    t.date "warranty_expiry"
    t.index ["employee_id"], name: "index_assets_on_employee_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.time "check_in"
    t.time "check_out"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "employee_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.decimal "working_hours"
    t.index ["employee_id"], name: "index_attendance_records_on_employee_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.date "applied_date"
    t.string "availability"
    t.string "cover_letter"
    t.datetime "created_at", null: false
    t.string "current_company"
    t.string "department"
    t.string "education"
    t.string "email"
    t.string "expected_salary"
    t.string "experience"
    t.date "last_contact"
    t.string "location"
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.string "position"
    t.string "resume"
    t.text "skills"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.text "address"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "employee_count"
    t.string "industry"
    t.string "name"
    t.string "timezone"
    t.datetime "updated_at", null: false
  end

  create_table "departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "employee_benefits", force: :cascade do |t|
    t.string "benefit_type"
    t.decimal "cost"
    t.string "coverage"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.date "end_date"
    t.string "name"
    t.string "provider"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_employee_benefits_on_employee_id"
  end

  create_table "employee_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_type"
    t.integer "employee_id", null: false
    t.date "expiry_date"
    t.string "file_size"
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
    t.date "upload_date"
    t.string "uploaded_by"
    t.index ["employee_id"], name: "index_employee_documents_on_employee_id"
  end

  create_table "employee_trainings", force: :cascade do |t|
    t.string "certificate"
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.date "end_date"
    t.integer "hours", default: 0
    t.string "name"
    t.integer "progress"
    t.string "provider"
    t.text "skills"
    t.date "start_date"
    t.string "status"
    t.string "training_type"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_employee_trainings_on_employee_id"
  end

  create_table "employees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.date "date_of_joining"
    t.integer "department_id", null: false
    t.string "designation"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "manager_id"
    t.string "phone"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  create_table "interviews", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.datetime "created_at", null: false
    t.text "feedback"
    t.string "interview_type"
    t.string "interviewer"
    t.text "notes"
    t.integer "rating"
    t.date "scheduled_date"
    t.time "scheduled_time"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_interviews_on_candidate_id"
  end

  create_table "job_openings", force: :cascade do |t|
    t.integer "applications"
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.text "description"
    t.string "experience"
    t.string "job_type"
    t.string "location"
    t.date "posted"
    t.string "requirements"
    t.integer "salary_max"
    t.integer "salary_min"
    t.string "skills"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "vacancies"
    t.index ["department_id"], name: "index_job_openings_on_department_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "leave_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days"
    t.string "emergency_contact"
    t.integer "employee_id", null: false
    t.date "end_date"
    t.boolean "half_day"
    t.string "half_day_period"
    t.text "handover_notes"
    t.datetime "hr_approved_at"
    t.integer "hr_approved_by_id"
    t.string "leave_type"
    t.datetime "manager_approved_at"
    t.integer "manager_approved_by_id"
    t.text "reason"
    t.datetime "rejected_at"
    t.integer "rejected_by_id"
    t.text "rejected_reason"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
    t.index ["hr_approved_by_id"], name: "index_leave_requests_on_hr_approved_by_id"
    t.index ["manager_approved_by_id"], name: "index_leave_requests_on_manager_approved_by_id"
    t.index ["rejected_by_id"], name: "index_leave_requests_on_rejected_by_id"
  end

  create_table "maintenance_records", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "maintenance_date"
    t.string "maintenance_type"
    t.date "next_maintenance"
    t.string "performed_by"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_maintenance_records_on_asset_id"
  end

  create_table "offboarding_employees", force: :cascade do |t|
    t.string "assigned_to"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.date "last_working_day"
    t.text "notes"
    t.integer "progress"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_offboarding_employees_on_employee_id"
  end

  create_table "offboarding_tasks", force: :cascade do |t|
    t.string "assigned_to"
    t.string "category"
    t.date "completed_date"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "documents"
    t.date "due_date"
    t.boolean "is_completed"
    t.integer "offboarding_employee_id", null: false
    t.string "priority"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["offboarding_employee_id"], name: "index_offboarding_tasks_on_offboarding_employee_id"
  end

  create_table "onboarding_employees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.text "notes"
    t.integer "progress"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_onboarding_employees_on_employee_id"
  end

  create_table "onboarding_tasks", force: :cascade do |t|
    t.string "assigned_to"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "documents"
    t.date "due_date"
    t.boolean "is_completed"
    t.integer "onboarding_employee_id", null: false
    t.string "priority"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["onboarding_employee_id"], name: "index_onboarding_tasks_on_onboarding_employee_id"
  end

  create_table "payrolls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.decimal "gross_salary"
    t.string "month"
    t.decimal "net_salary"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
  end

  create_table "performance_goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.integer "employee_id", null: false
    t.integer "progress"
    t.string "status"
    t.string "target"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_performance_goals_on_employee_id"
  end

  create_table "performance_reviews", force: :cascade do |t|
    t.text "achievements"
    t.text "areas_for_improvement"
    t.text "comments"
    t.datetime "created_at", null: false
    t.integer "employee_id", null: false
    t.text "goals"
    t.string "period"
    t.decimal "rating"
    t.date "review_date"
    t.string "reviewer"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_performance_reviews_on_employee_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_permissions_on_name", unique: true
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "permission_id", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "salary_structures", force: :cascade do |t|
    t.decimal "allowances"
    t.decimal "basic"
    t.datetime "created_at", null: false
    t.decimal "deductions"
    t.date "effective_from"
    t.integer "employee_id", null: false
    t.decimal "hra"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_salary_structures_on_employee_id"
  end

  create_table "timesheets", force: :cascade do |t|
    t.string "approved_by"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "employee_id", null: false
    t.decimal "hours"
    t.text "notes"
    t.string "project"
    t.string "status"
    t.string "task"
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_timesheets_on_employee_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", null: false
    t.integer "employee_id"
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_login_at"
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
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
  add_foreign_key "leave_requests", "users", column: "hr_approved_by_id"
  add_foreign_key "leave_requests", "users", column: "manager_approved_by_id"
  add_foreign_key "leave_requests", "users", column: "rejected_by_id"
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
  add_foreign_key "users", "employees"
end
