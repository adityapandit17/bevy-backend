# frozen_string_literal: true

class AddMultiTenantCompanyId < ActiveRecord::Migration[8.1]
  TENANT_TABLES = %w[
    departments employees attendance_records attendance_sessions
    leave_requests leave_policies payrolls salary_structures timesheets pending_tasks
    onboarding_employees onboarding_tasks offboarding_employees offboarding_tasks
    job_openings candidates interviews assets asset_allocations maintenance_records
    channels channel_memberships messages huddles huddle_participants notifications
    helpdesk_tickets ticket_comments knowledge_articles sla_workflows policy_documents
    digital_signatures employee_documents employee_benefits employee_trainings
    performance_reviews performance_goals recognitions events user_preferences
  ].freeze

  def up
    default_company = ensure_default_company

    TENANT_TABLES.each do |table|
      next if column_exists?(table, :company_id)

      add_reference table, :company, foreign_key: true, index: true
    end

    unless column_exists?(:roles, :company_id)
      add_reference :roles, :company, foreign_key: true, index: true, null: true
    end

    backfill_company_ids(default_company)

    (TENANT_TABLES + %w[users]).each do |table|
      change_column_null table, :company_id, false
    end

    replace_unique_indexes
  end

  def down
    revert_unique_indexes

    (TENANT_TABLES + %w[roles]).each do |table|
      next unless column_exists?(table, :company_id)

      remove_reference table, :company, foreign_key: true, index: true
    end

    change_column_null :users, :company_id, true if column_exists?(:users, :company_id)
  end

  private

  def ensure_default_company
    row = execute("SELECT id FROM companies ORDER BY id ASC LIMIT 1").first
    return company_handle(row["id"]) if row

    now = connection.quote(Time.current)
    columns = %w[name code industry employee_count timezone currency created_at updated_at]
    values = [
      connection.quote("BevyHR Demo"),
      connection.quote("DEMO"),
      connection.quote("technology"),
      connection.quote("51-200"),
      connection.quote("asia-kolkata"),
      connection.quote("inr"),
      now,
      now
    ]

    if column_exists?(:companies, :country_code)
      columns << "country_code"
      values << connection.quote("IN")
    end

    if column_exists?(:companies, :dashboard_layout)
      columns << "dashboard_layout"
      values << connection.quote("top_nav")
    end

    if column_exists?(:companies, :status)
      columns << "status"
      values << connection.quote("active")
    end

    if column_exists?(:companies, :plan)
      columns << "plan"
      values << connection.quote("professional")
    end

    inserted = execute(
      "INSERT INTO companies (#{columns.join(', ')}) VALUES (#{values.join(', ')}) RETURNING id"
    ).first

    company_handle(inserted["id"])
  end

  def company_handle(id)
    Struct.new(:id).new(id)
  end

  def backfill_company_ids(default_company)
    company_id = default_company.id

    execute("UPDATE users SET company_id = #{company_id} WHERE company_id IS NULL")

    TENANT_TABLES.each do |table|
      execute("UPDATE #{table} SET company_id = #{company_id} WHERE company_id IS NULL")
    end

    # System roles remain global (company_id NULL)
    execute("UPDATE roles SET company_id = NULL WHERE company_id IS NOT NULL")
  end

  def deduplicate_department_names
    execute(<<-SQL.squish)
      UPDATE departments AS d
      SET name = d.name || ' ' || d.id::text
      FROM (
        SELECT company_id, name
        FROM departments
        GROUP BY company_id, name
        HAVING COUNT(*) > 1
      ) AS dupes
      WHERE d.company_id = dupes.company_id
        AND d.name = dupes.name
        AND d.id NOT IN (
          SELECT MIN(id) FROM departments
          GROUP BY company_id, name
          HAVING COUNT(*) > 1
        )
    SQL
  end

  def replace_unique_indexes
    if index_exists?(:users, :email)
      remove_index :users, :email
      add_index :users, %i[company_id email], unique: true
    end

    if index_exists?(:employees, :email)
      remove_index :employees, :email
      add_index :employees, %i[company_id email], unique: true
    end

    deduplicate_department_names

    add_index :departments, %i[company_id name], unique: true unless index_exists?(:departments, %i[company_id name])

    if index_exists?(:roles, :name)
      remove_index :roles, :name
      add_index :roles, :name, unique: true, where: "company_id IS NULL", name: "index_roles_on_name_system"
      add_index :roles, %i[company_id name], unique: true, where: "company_id IS NOT NULL",
                name: "index_roles_on_company_id_and_name"
    end

    if index_exists?(:job_openings, :public_slug)
      remove_index :job_openings, :public_slug
      add_index :job_openings, %i[company_id public_slug], unique: true, where: "public_slug IS NOT NULL",
                name: "index_job_openings_on_company_id_and_public_slug"
    end
  end

  def revert_unique_indexes
    if index_exists?(:users, %i[company_id email])
      remove_index :users, column: %i[company_id email]
      add_index :users, :email, unique: true
    end

    if index_exists?(:employees, %i[company_id email])
      remove_index :employees, column: %i[company_id email]
      add_index :employees, :email, unique: true
    end

    remove_index :departments, column: %i[company_id name] if index_exists?(:departments, %i[company_id name])

    if index_exists?(:roles, name: "index_roles_on_name_system")
      remove_index :roles, name: "index_roles_on_name_system"
      remove_index :roles, name: "index_roles_on_company_id_and_name"
      add_index :roles, :name, unique: true
    end

    if index_exists?(:job_openings, name: "index_job_openings_on_company_id_and_public_slug")
      remove_index :job_openings, name: "index_job_openings_on_company_id_and_public_slug"
      add_index :job_openings, :public_slug, unique: true
    end
  end
end
