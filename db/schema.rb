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

ActiveRecord::Schema[8.1].define(version: 2026_07_01_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "asset_allocations", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.date "assigned_date"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.text "notes"
    t.date "return_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_asset_allocations_on_asset_id"
    t.index ["company_id"], name: "index_asset_allocations_on_company_id"
    t.index ["employee_id"], name: "index_asset_allocations_on_employee_id"
  end

  create_table "assets", force: :cascade do |t|
    t.string "asset_tag", null: false
    t.string "asset_type"
    t.string "brand"
    t.bigint "company_id", null: false
    t.string "condition"
    t.datetime "created_at", null: false
    t.decimal "current_value"
    t.string "department"
    t.bigint "employee_id"
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
    t.index ["asset_tag"], name: "index_assets_on_asset_tag", unique: true
    t.index ["company_id"], name: "index_assets_on_company_id"
    t.index ["employee_id"], name: "index_assets_on_employee_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.bigint "employee_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.decimal "working_hours"
    t.index ["company_id"], name: "index_attendance_records_on_company_id"
    t.index ["employee_id", "date"], name: "index_attendance_records_on_employee_id_and_date_unique", unique: true
    t.index ["employee_id"], name: "index_attendance_records_on_employee_id"
  end

  create_table "attendance_sessions", force: :cascade do |t|
    t.bigint "attendance_record_id", null: false
    t.datetime "check_in"
    t.datetime "check_out"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.decimal "session_hours", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["attendance_record_id"], name: "index_attendance_sessions_on_attendance_record_id"
    t.index ["company_id"], name: "index_attendance_sessions_on_company_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.date "applied_date"
    t.boolean "archived", default: false, null: false
    t.string "availability"
    t.bigint "company_id", null: false
    t.string "cover_letter"
    t.datetime "created_at", null: false
    t.string "current_company"
    t.date "date_of_birth"
    t.string "department"
    t.string "education"
    t.string "email"
    t.string "expected_salary"
    t.string "experience"
    t.string "first_name"
    t.bigint "job_opening_id"
    t.date "last_contact"
    t.string "last_name"
    t.string "linkedin_url"
    t.string "location"
    t.text "notes"
    t.string "phone"
    t.string "position"
    t.string "resume"
    t.text "skills"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_candidates_on_archived"
    t.index ["company_id"], name: "index_candidates_on_company_id"
    t.index ["job_opening_id"], name: "index_candidates_on_job_opening_id"
  end

  create_table "channel_memberships", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["channel_id", "user_id"], name: "index_channel_memberships_on_channel_id_and_user_id", unique: true
    t.index ["channel_id"], name: "index_channel_memberships_on_channel_id"
    t.index ["company_id"], name: "index_channel_memberships_on_company_id"
    t.index ["user_id"], name: "index_channel_memberships_on_user_id"
  end

  create_table "channels", force: :cascade do |t|
    t.string "channel_type", default: "channel", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.boolean "is_private", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_type", "name"], name: "index_channels_on_channel_type_and_name"
    t.index ["channel_type"], name: "index_channels_on_channel_type"
    t.index ["company_id"], name: "index_channels_on_company_id"
    t.index ["created_by_id"], name: "index_channels_on_created_by_id"
    t.index ["name"], name: "index_channels_on_name"
  end

  create_table "companies", force: :cascade do |t|
    t.text "address"
    t.integer "billable_seats", default: 1, null: false
    t.string "billing_cycle", default: "monthly", null: false
    t.string "careers_slug"
    t.string "code"
    t.string "contact_email"
    t.string "contact_name"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "dashboard_layout", default: "top_nav", null: false
    t.string "employee_count"
    t.string "gateway_customer_id"
    t.string "gateway_subscription_id"
    t.text "google_calendar_access_token"
    t.datetime "google_calendar_connected_at"
    t.bigint "google_calendar_connected_by_user_id"
    t.string "google_calendar_email"
    t.text "google_calendar_refresh_token"
    t.datetime "google_calendar_token_expires_at"
    t.string "industry"
    t.integer "lunch_duration_minutes", default: 60
    t.integer "max_employees", default: 50
    t.string "name"
    t.string "payment_gateway", default: "stripe", null: false
    t.string "plan", default: "starter", null: false
    t.datetime "renews_at"
    t.string "status", default: "active", null: false
    t.string "timezone"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.decimal "weekly_working_hours", precision: 5, scale: 2, default: "40.0"
    t.string "work_end_time", default: "18:00"
    t.string "work_start_time", default: "09:00"
    t.index ["careers_slug"], name: "index_companies_on_careers_slug", unique: true
    t.index ["country_code"], name: "index_companies_on_country_code"
    t.index ["gateway_customer_id"], name: "index_companies_on_gateway_customer_id"
    t.index ["gateway_subscription_id"], name: "index_companies_on_gateway_subscription_id"
  end

  create_table "company_feature_flags", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "key"], name: "index_company_feature_flags_on_company_id_and_key", unique: true
    t.index ["company_id"], name: "index_company_feature_flags_on_company_id"
  end

  create_table "departments", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_departments_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_departments_on_company_id"
  end

  create_table "digital_signatures", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "device_info"
    t.bigint "employee_id", null: false
    t.string "ip_address"
    t.bigint "policy_document_id", null: false
    t.string "signature_type"
    t.date "signed_date"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["company_id"], name: "index_digital_signatures_on_company_id"
    t.index ["employee_id"], name: "index_digital_signatures_on_employee_id"
    t.index ["policy_document_id", "employee_id"], name: "index_digital_signatures_on_policy_and_employee", unique: true
    t.index ["policy_document_id"], name: "index_digital_signatures_on_policy_document_id"
    t.index ["signed_date"], name: "index_digital_signatures_on_signed_date"
    t.index ["status"], name: "index_digital_signatures_on_status"
  end

  create_table "employee_benefits", force: :cascade do |t|
    t.string "benefit_type"
    t.bigint "company_id", null: false
    t.decimal "cost"
    t.string "coverage"
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.date "end_date"
    t.string "name"
    t.string "provider"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employee_benefits_on_company_id"
    t.index ["employee_id"], name: "index_employee_benefits_on_employee_id"
  end

  create_table "employee_documents", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "document_type"
    t.bigint "employee_id", null: false
    t.date "expiry_date"
    t.string "file_path"
    t.string "file_size"
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
    t.date "upload_date"
    t.string "uploaded_by"
    t.index ["company_id"], name: "index_employee_documents_on_company_id"
    t.index ["employee_id"], name: "index_employee_documents_on_employee_id"
  end

  create_table "employee_trainings", force: :cascade do |t|
    t.string "certificate"
    t.bigint "company_id", null: false
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
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
    t.index ["company_id"], name: "index_employee_trainings_on_company_id"
    t.index ["employee_id"], name: "index_employee_trainings_on_employee_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "badge_level"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.date "date_of_joining"
    t.bigint "department_id", null: false
    t.string "designation"
    t.string "email"
    t.integer "employee_number", null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "manager_id"
    t.string "phone"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["badge_level"], name: "index_employees_on_badge_level"
    t.index ["company_id", "email"], name: "index_employees_on_company_id_and_email", unique: true
    t.index ["company_id", "employee_number"], name: "index_employees_on_company_id_and_employee_number", unique: true
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["manager_id"], name: "index_employees_on_manager_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "attendee_ids"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time", null: false
    t.string "event_type", default: "meeting"
    t.string "location"
    t.integer "organizer_id"
    t.datetime "start_time", null: false
    t.string "status", default: "scheduled"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "helpdesk_tickets", force: :cascade do |t|
    t.integer "assigned_to_id"
    t.string "category"
    t.string "channel", default: "portal"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "priority", default: "medium"
    t.integer "requester_id"
    t.integer "sla_hours"
    t.string "sla_status", default: "on-track"
    t.string "status", default: "open"
    t.text "tags"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_helpdesk_tickets_on_assigned_to_id"
    t.index ["category"], name: "index_helpdesk_tickets_on_category"
    t.index ["company_id"], name: "index_helpdesk_tickets_on_company_id"
    t.index ["priority"], name: "index_helpdesk_tickets_on_priority"
    t.index ["requester_id"], name: "index_helpdesk_tickets_on_requester_id"
    t.index ["status"], name: "index_helpdesk_tickets_on_status"
  end

  create_table "huddle_participants", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "huddle_id", null: false
    t.datetime "joined_at"
    t.datetime "left_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_huddle_participants_on_company_id"
    t.index ["huddle_id", "user_id"], name: "index_huddle_participants_on_huddle_id_and_user_id", unique: true
    t.index ["huddle_id"], name: "index_huddle_participants_on_huddle_id"
    t.index ["user_id"], name: "index_huddle_participants_on_user_id"
  end

  create_table "huddles", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.datetime "started_at", null: false
    t.bigint "started_by_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "status"], name: "index_huddles_on_channel_id_and_status"
    t.index ["channel_id"], name: "index_huddles_on_channel_id"
    t.index ["company_id"], name: "index_huddles_on_company_id"
    t.index ["started_at"], name: "index_huddles_on_started_at"
    t.index ["started_by_id"], name: "index_huddles_on_started_by_id"
    t.index ["status"], name: "index_huddles_on_status"
  end

  create_table "interviews", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes", default: 60, null: false
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
    t.index ["company_id"], name: "index_interviews_on_company_id"
  end

  create_table "job_openings", force: :cascade do |t|
    t.integer "applications"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "department_id", null: false
    t.text "description"
    t.string "experience"
    t.string "job_type"
    t.string "location"
    t.date "posted"
    t.string "public_slug"
    t.string "requirements"
    t.integer "salary_max"
    t.integer "salary_min"
    t.string "skills"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "vacancies"
    t.index ["company_id", "public_slug"], name: "index_job_openings_on_company_id_and_public_slug", unique: true, where: "(public_slug IS NOT NULL)"
    t.index ["company_id"], name: "index_job_openings_on_company_id"
    t.index ["department_id"], name: "index_job_openings_on_department_id"
  end

  create_table "knowledge_articles", force: :cascade do |t|
    t.string "author"
    t.string "category"
    t.bigint "company_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "helpful", default: 0
    t.datetime "last_updated"
    t.string "status", default: "draft"
    t.text "tags"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "views", default: 0
    t.index ["category"], name: "index_knowledge_articles_on_category"
    t.index ["company_id"], name: "index_knowledge_articles_on_company_id"
    t.index ["status"], name: "index_knowledge_articles_on_status"
  end

  create_table "leave_policies", force: :cascade do |t|
    t.boolean "active"
    t.integer "annual_leave"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "holidays_per_year"
    t.integer "maternity_leave"
    t.integer "other_leave"
    t.integer "paternity_leave"
    t.integer "personal_leave"
    t.integer "sick_leave"
    t.integer "unpaid_leave"
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["company_id"], name: "index_leave_policies_on_company_id"
  end

  create_table "leave_requests", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "days"
    t.string "emergency_contact"
    t.bigint "employee_id", null: false
    t.date "end_date"
    t.boolean "half_day"
    t.string "half_day_period"
    t.text "handover_notes"
    t.datetime "hr_approved_at"
    t.bigint "hr_approved_by_id"
    t.string "leave_type"
    t.datetime "manager_approved_at"
    t.bigint "manager_approved_by_id"
    t.text "reason"
    t.datetime "rejected_at"
    t.bigint "rejected_by_id"
    t.text "rejected_reason"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leave_requests_on_company_id"
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
    t.index ["hr_approved_by_id"], name: "index_leave_requests_on_hr_approved_by_id"
    t.index ["manager_approved_by_id"], name: "index_leave_requests_on_manager_approved_by_id"
    t.index ["rejected_by_id"], name: "index_leave_requests_on_rejected_by_id"
    t.index ["status", "start_date", "end_date"], name: "index_leave_requests_on_status_and_dates"
  end

  create_table "maintenance_records", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.bigint "company_id", null: false
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "maintenance_date"
    t.string "maintenance_type"
    t.date "next_maintenance"
    t.string "performed_by"
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_maintenance_records_on_asset_id"
    t.index ["company_id"], name: "index_maintenance_records_on_company_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.bigint "company_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["channel_id", "created_at"], name: "index_messages_on_channel_id_and_created_at"
    t.index ["channel_id"], name: "index_messages_on_channel_id"
    t.index ["company_id"], name: "index_messages_on_company_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action_url"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.string "notification_type", null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "offboarding_employees", force: :cascade do |t|
    t.string "assigned_to"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.date "last_working_day"
    t.text "notes"
    t.integer "progress"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_offboarding_employees_on_company_id"
    t.index ["employee_id"], name: "index_offboarding_employees_on_employee_id"
  end

  create_table "offboarding_tasks", force: :cascade do |t|
    t.string "assigned_to"
    t.string "category"
    t.bigint "company_id", null: false
    t.date "completed_date"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "documents"
    t.date "due_date"
    t.boolean "is_completed"
    t.bigint "offboarding_employee_id", null: false
    t.string "priority"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_offboarding_tasks_on_company_id"
    t.index ["offboarding_employee_id"], name: "index_offboarding_tasks_on_offboarding_employee_id"
  end

  create_table "onboarding_employees", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.text "notes"
    t.integer "progress"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_onboarding_employees_on_company_id"
    t.index ["employee_id"], name: "index_onboarding_employees_on_employee_id"
  end

  create_table "onboarding_tasks", force: :cascade do |t|
    t.string "assigned_to"
    t.string "category"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "documents"
    t.date "due_date"
    t.boolean "is_completed"
    t.bigint "onboarding_employee_id", null: false
    t.string "priority"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_onboarding_tasks_on_company_id"
    t.index ["onboarding_employee_id"], name: "index_onboarding_tasks_on_onboarding_employee_id"
  end

  create_table "payrolls", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.json "deductions_breakdown", default: {}
    t.json "earnings_breakdown", default: {}
    t.bigint "employee_id", null: false
    t.decimal "gross_salary"
    t.decimal "leave_deduction", precision: 12, scale: 2
    t.string "month"
    t.decimal "net_salary"
    t.decimal "payable_days", precision: 10, scale: 2
    t.datetime "processed_at"
    t.string "run_mode"
    t.string "status"
    t.decimal "unpaid_days", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.integer "working_days"
    t.index ["company_id"], name: "index_payrolls_on_company_id"
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
  end

  create_table "pending_tasks", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "priority", default: "medium"
    t.string "status", default: "pending"
    t.bigint "taskable_id", null: false
    t.string "taskable_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id", "status", "taskable_type"], name: "index_pending_tasks_on_assignee_status_type"
    t.index ["assigned_to_id", "status"], name: "index_pending_tasks_on_assigned_to_id_and_status"
    t.index ["assigned_to_id"], name: "index_pending_tasks_on_assigned_to_id"
    t.index ["company_id"], name: "index_pending_tasks_on_company_id"
    t.index ["due_date"], name: "index_pending_tasks_on_due_date"
    t.index ["status"], name: "index_pending_tasks_on_status"
    t.index ["taskable_type", "taskable_id"], name: "index_pending_tasks_on_taskable"
    t.index ["taskable_type", "taskable_id"], name: "index_pending_tasks_on_taskable_type_and_taskable_id"
  end

  create_table "performance_goals", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.bigint "employee_id", null: false
    t.integer "progress"
    t.string "status"
    t.string "target"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_performance_goals_on_company_id"
    t.index ["employee_id"], name: "index_performance_goals_on_employee_id"
  end

  create_table "performance_reviews", force: :cascade do |t|
    t.text "achievements"
    t.text "areas_for_improvement"
    t.text "comments"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.text "goals"
    t.string "period"
    t.decimal "rating"
    t.date "review_date"
    t.string "reviewer"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_performance_reviews_on_company_id"
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

  create_table "platform_admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.datetime "last_login_at"
    t.string "last_name", null: false
    t.string "role", default: "super_admin", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_platform_admin_users_on_email", unique: true
  end

  create_table "platform_announcements", force: :cascade do |t|
    t.string "audience", default: "all", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.text "message", null: false
    t.bigint "platform_admin_user_id"
    t.datetime "starts_at"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_admin_user_id"], name: "index_platform_announcements_on_platform_admin_user_id"
    t.index ["status"], name: "index_platform_announcements_on_status"
  end

  create_table "platform_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "platform_admin_user_id", null: false
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_platform_audit_logs_on_action"
    t.index ["company_id", "created_at"], name: "index_platform_audit_logs_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_platform_audit_logs_on_company_id"
    t.index ["created_at"], name: "index_platform_audit_logs_on_created_at"
    t.index ["platform_admin_user_id", "created_at"], name: "idx_on_platform_admin_user_id_created_at_bfd50b8af0"
    t.index ["platform_admin_user_id"], name: "index_platform_audit_logs_on_platform_admin_user_id"
    t.index ["resource_type", "resource_id"], name: "index_platform_audit_logs_on_resource_type_and_resource_id"
  end

  create_table "platform_campaigns", force: :cascade do |t|
    t.string "audience"
    t.integer "budget", default: 0, null: false
    t.string "channel", default: "email", null: false
    t.integer "conversions", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "name", null: false
    t.integer "sent_count", default: 0, null: false
    t.date "start_date"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_platform_campaigns_on_status"
  end

  create_table "platform_follow_ups", force: :cascade do |t|
    t.string "assignee", null: false
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.string "follow_up_type", default: "call", null: false
    t.text "notes"
    t.bigint "platform_inquiry_id", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_platform_follow_ups_on_due_date"
    t.index ["platform_inquiry_id"], name: "index_platform_follow_ups_on_platform_inquiry_id"
    t.index ["status"], name: "index_platform_follow_ups_on_status"
  end

  create_table "platform_inquiries", force: :cascade do |t|
    t.string "assignee"
    t.string "company_name", null: false
    t.string "contact_name", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "estimated_seats", default: 10
    t.text "notes"
    t.string "plan_interest", default: "starter"
    t.string "source", default: "website"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_platform_inquiries_on_email"
    t.index ["status"], name: "index_platform_inquiries_on_status"
  end

  create_table "platform_invoices", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.date "billing_period_end"
    t.date "billing_period_start"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "gateway_invoice_id"
    t.string "invoice_number", null: false
    t.text "notes"
    t.datetime "paid_at"
    t.string "payment_gateway"
    t.string "plan"
    t.string "receipt_url"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_platform_invoices_on_company_id"
    t.index ["gateway_invoice_id"], name: "index_platform_invoices_on_gateway_invoice_id"
    t.index ["invoice_number"], name: "index_platform_invoices_on_invoice_number", unique: true
    t.index ["status"], name: "index_platform_invoices_on_status"
  end

  create_table "platform_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_platform_settings_on_key", unique: true
  end

  create_table "policy_documents", force: :cascade do |t|
    t.string "category", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "downloads", default: 0
    t.date "expiry_date"
    t.string "file_path", null: false
    t.integer "file_size", default: 0
    t.date "last_updated"
    t.boolean "requires_signature", default: false
    t.string "status", default: "active"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "uploaded_by"
    t.string "version"
    t.index ["category"], name: "index_policy_documents_on_category"
    t.index ["company_id"], name: "index_policy_documents_on_company_id"
    t.index ["status"], name: "index_policy_documents_on_status"
  end

  create_table "pricing_plans", force: :cascade do |t|
    t.integer "annual_price", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "features", default: [], null: false
    t.string "gateway_price_annual_id"
    t.string "gateway_price_monthly_id"
    t.string "gateway_product_id"
    t.integer "max_employees", default: 50, null: false
    t.integer "monthly_price", default: 0, null: false
    t.string "name", null: false
    t.integer "per_seat_price", default: 0, null: false
    t.boolean "popular", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pricing_plans_on_slug", unique: true
  end

  create_table "recognitions", force: :cascade do |t|
    t.string "category"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "given_by_id", null: false
    t.bigint "received_by_id", null: false
    t.string "recognition_type", null: false
    t.string "status", default: "active"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_recognitions_on_company_id"
    t.index ["created_at"], name: "index_recognitions_on_created_at"
    t.index ["given_by_id"], name: "index_recognitions_on_given_by_id"
    t.index ["received_by_id"], name: "index_recognitions_on_received_by_id"
    t.index ["recognition_type"], name: "index_recognitions_on_recognition_type"
    t.index ["status"], name: "index_recognitions_on_status"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_roles_on_company_id_and_name", unique: true, where: "(company_id IS NOT NULL)"
    t.index ["company_id"], name: "index_roles_on_company_id"
    t.index ["name"], name: "index_roles_on_name_system", unique: true, where: "(company_id IS NULL)"
  end

  create_table "salary_structures", force: :cascade do |t|
    t.decimal "allowances"
    t.decimal "annual_ctc", precision: 10, scale: 2, default: "0.0"
    t.decimal "basic"
    t.decimal "bonus", precision: 10, scale: 2, default: "0.0"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.decimal "deductions"
    t.bigint "department_id"
    t.date "effective_from"
    t.date "effective_upto"
    t.bigint "employee_id", null: false
    t.decimal "esi", precision: 10, scale: 2, default: "0.0"
    t.decimal "hra"
    t.decimal "income_tax", precision: 10, scale: 2, default: "0.0"
    t.string "level"
    t.decimal "monthly_ctc", precision: 10, scale: 2, default: "0.0"
    t.decimal "pf", precision: 10, scale: 2, default: "0.0"
    t.decimal "professional_tax", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_salary_structures_on_company_id"
    t.index ["department_id"], name: "index_salary_structures_on_department_id"
    t.index ["employee_id"], name: "index_salary_structures_on_employee_id"
  end

  create_table "sla_workflows", force: :cascade do |t|
    t.decimal "avg_resolution_hours", precision: 10, scale: 2
    t.string "category"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "escalation_levels"
    t.string "name", null: false
    t.string "priority", default: "medium"
    t.integer "sla_hours", null: false
    t.string "status", default: "active"
    t.integer "tickets_handled", default: 0
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_sla_workflows_on_category"
    t.index ["company_id"], name: "index_sla_workflows_on_company_id"
    t.index ["status"], name: "index_sla_workflows_on_status"
  end

  create_table "subscription_requests", force: :cascade do |t|
    t.integer "amount", default: 0
    t.string "billing_cycle", default: "monthly", null: false
    t.bigint "company_id"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "plan", default: "starter", null: false
    t.string "request_type", default: "new_tenant", null: false
    t.string "requested_by"
    t.integer "seats", default: 10
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscription_requests_on_company_id"
    t.index ["status"], name: "index_subscription_requests_on_status"
  end

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "employee_id"
    t.integer "helpdesk_ticket_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["company_id"], name: "index_ticket_comments_on_company_id"
    t.index ["created_at"], name: "index_ticket_comments_on_created_at"
    t.index ["employee_id"], name: "index_ticket_comments_on_employee_id"
    t.index ["helpdesk_ticket_id"], name: "index_ticket_comments_on_helpdesk_ticket_id"
    t.index ["user_id"], name: "index_ticket_comments_on_user_id"
  end

  create_table "timesheets", force: :cascade do |t|
    t.string "approved_by"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.bigint "employee_id", null: false
    t.decimal "hours"
    t.text "notes"
    t.string "project"
    t.string "status"
    t.string "task"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_timesheets_on_company_id"
    t.index ["employee_id"], name: "index_timesheets_on_employee_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.boolean "attendance_notifications", default: true
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "date_format", default: "MM/DD/YYYY"
    t.boolean "email_notifications", default: true
    t.string "language", default: "en"
    t.boolean "leave_notifications", default: true
    t.boolean "payroll_notifications", default: false
    t.boolean "push_notifications", default: true
    t.boolean "system_notifications", default: true
    t.string "theme", default: "light"
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_user_preferences_on_company_id"
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.bigint "employee_id"
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
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
    t.index ["company_id", "email"], name: "index_users_on_company_id_and_email", unique: true
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["employee_id"], name: "index_users_on_employee_id"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "asset_allocations", "assets"
  add_foreign_key "asset_allocations", "companies"
  add_foreign_key "asset_allocations", "employees"
  add_foreign_key "assets", "companies"
  add_foreign_key "assets", "employees"
  add_foreign_key "attendance_records", "companies"
  add_foreign_key "attendance_records", "employees"
  add_foreign_key "attendance_sessions", "attendance_records"
  add_foreign_key "attendance_sessions", "companies"
  add_foreign_key "candidates", "companies"
  add_foreign_key "candidates", "job_openings"
  add_foreign_key "channel_memberships", "channels"
  add_foreign_key "channel_memberships", "companies"
  add_foreign_key "channel_memberships", "users"
  add_foreign_key "channels", "companies"
  add_foreign_key "channels", "users", column: "created_by_id"
  add_foreign_key "company_feature_flags", "companies"
  add_foreign_key "departments", "companies"
  add_foreign_key "digital_signatures", "companies"
  add_foreign_key "digital_signatures", "employees"
  add_foreign_key "digital_signatures", "policy_documents"
  add_foreign_key "employee_benefits", "companies"
  add_foreign_key "employee_benefits", "employees"
  add_foreign_key "employee_documents", "companies"
  add_foreign_key "employee_documents", "employees"
  add_foreign_key "employee_trainings", "companies"
  add_foreign_key "employee_trainings", "employees"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "employees", column: "manager_id"
  add_foreign_key "events", "companies"
  add_foreign_key "helpdesk_tickets", "companies"
  add_foreign_key "huddle_participants", "companies"
  add_foreign_key "huddle_participants", "huddles"
  add_foreign_key "huddle_participants", "users"
  add_foreign_key "huddles", "channels"
  add_foreign_key "huddles", "companies"
  add_foreign_key "huddles", "users", column: "started_by_id"
  add_foreign_key "interviews", "candidates"
  add_foreign_key "interviews", "companies"
  add_foreign_key "job_openings", "companies"
  add_foreign_key "job_openings", "departments"
  add_foreign_key "knowledge_articles", "companies"
  add_foreign_key "leave_policies", "companies"
  add_foreign_key "leave_requests", "companies"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "leave_requests", "users", column: "hr_approved_by_id"
  add_foreign_key "leave_requests", "users", column: "manager_approved_by_id"
  add_foreign_key "leave_requests", "users", column: "rejected_by_id"
  add_foreign_key "maintenance_records", "assets"
  add_foreign_key "maintenance_records", "companies"
  add_foreign_key "messages", "channels"
  add_foreign_key "messages", "companies"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "companies"
  add_foreign_key "notifications", "users"
  add_foreign_key "offboarding_employees", "companies"
  add_foreign_key "offboarding_employees", "employees"
  add_foreign_key "offboarding_tasks", "companies"
  add_foreign_key "offboarding_tasks", "offboarding_employees"
  add_foreign_key "onboarding_employees", "companies"
  add_foreign_key "onboarding_employees", "employees"
  add_foreign_key "onboarding_tasks", "companies"
  add_foreign_key "onboarding_tasks", "onboarding_employees"
  add_foreign_key "payrolls", "companies"
  add_foreign_key "payrolls", "employees"
  add_foreign_key "pending_tasks", "companies"
  add_foreign_key "pending_tasks", "employees", column: "assigned_to_id"
  add_foreign_key "performance_goals", "companies"
  add_foreign_key "performance_goals", "employees"
  add_foreign_key "performance_reviews", "companies"
  add_foreign_key "performance_reviews", "employees"
  add_foreign_key "platform_announcements", "platform_admin_users"
  add_foreign_key "platform_audit_logs", "companies"
  add_foreign_key "platform_audit_logs", "platform_admin_users"
  add_foreign_key "platform_follow_ups", "platform_inquiries"
  add_foreign_key "platform_invoices", "companies"
  add_foreign_key "policy_documents", "companies"
  add_foreign_key "recognitions", "companies"
  add_foreign_key "recognitions", "employees", column: "received_by_id"
  add_foreign_key "recognitions", "users", column: "given_by_id"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "roles", "companies"
  add_foreign_key "salary_structures", "companies"
  add_foreign_key "salary_structures", "departments"
  add_foreign_key "salary_structures", "employees"
  add_foreign_key "sla_workflows", "companies"
  add_foreign_key "subscription_requests", "companies"
  add_foreign_key "ticket_comments", "companies"
  add_foreign_key "timesheets", "companies"
  add_foreign_key "timesheets", "employees"
  add_foreign_key "user_preferences", "companies"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "employees"
end
