# frozen_string_literal: true

class MultitenancyCompanyMembershipsAndCompanyIds < ActiveRecord::Migration[8.1]
  def up
    create_table :company_memberships do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :company_memberships, [ :company_id, :user_id ], unique: true

    tenant_tables = %w[
      departments employees job_openings assets asset_allocations attendance_records attendance_sessions
      candidates channels digital_signatures employee_benefits employee_documents employee_trainings
      events helpdesk_tickets huddles interviews knowledge_articles leave_policies leave_requests
      maintenance_records messages notifications offboarding_employees offboarding_tasks
      onboarding_employees onboarding_tasks payrolls pending_tasks performance_goals performance_reviews
      policy_documents recognitions salary_structures sla_workflows ticket_comments timesheets
    ]

    tenant_tables.each do |table|
      add_reference table.to_sym, :company, foreign_key: true, index: true
    end

    default_company = Company.first
    unless default_company
      default_company = Company.create!(
        name: "Default Company",
        code: "DEF",
        industry: "General",
        employee_count: "0",
        timezone: "UTC",
        currency: "USD"
      )
    end

    dc_id = default_company.id

    say_with_time "Backfill company_id on tenant tables" do
      execute <<~SQL.squish
        UPDATE departments SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE employees SET company_id = departments.company_id
        FROM departments WHERE employees.department_id = departments.id AND employees.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE job_openings SET company_id = departments.company_id
        FROM departments WHERE job_openings.department_id = departments.id AND job_openings.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE assets SET company_id = employees.company_id
        FROM employees WHERE assets.employee_id = employees.id AND assets.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE assets SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE asset_allocations SET company_id = assets.company_id
        FROM assets WHERE asset_allocations.asset_id = assets.id AND asset_allocations.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE attendance_records SET company_id = employees.company_id
        FROM employees WHERE attendance_records.employee_id = employees.id AND attendance_records.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE attendance_sessions SET company_id = attendance_records.company_id
        FROM attendance_records WHERE attendance_sessions.attendance_record_id = attendance_records.id
          AND attendance_sessions.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE candidates SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE channels SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE digital_signatures SET company_id = employees.company_id
        FROM employees WHERE digital_signatures.employee_id = employees.id AND digital_signatures.company_id IS NULL;
      SQL
      %w[employee_benefits employee_documents employee_trainings].each do |tbl|
        execute <<~SQL.squish
          UPDATE #{tbl} SET company_id = employees.company_id
          FROM employees WHERE #{tbl}.employee_id = employees.id AND #{tbl}.company_id IS NULL;
        SQL
      end
      execute <<~SQL.squish
        UPDATE events SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE helpdesk_tickets SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE huddles SET company_id = channels.company_id
        FROM channels WHERE huddles.channel_id = channels.id AND huddles.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE interviews SET company_id = candidates.company_id
        FROM candidates WHERE interviews.candidate_id = candidates.id AND interviews.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE knowledge_articles SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE leave_policies SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE leave_requests SET company_id = employees.company_id
        FROM employees WHERE leave_requests.employee_id = employees.id AND leave_requests.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE maintenance_records SET company_id = assets.company_id
        FROM assets WHERE maintenance_records.asset_id = assets.id AND maintenance_records.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE messages SET company_id = channels.company_id
        FROM channels WHERE messages.channel_id = channels.id AND messages.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE notifications SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE offboarding_employees SET company_id = employees.company_id
        FROM employees WHERE offboarding_employees.employee_id = employees.id AND offboarding_employees.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE offboarding_tasks SET company_id = offboarding_employees.company_id
        FROM offboarding_employees WHERE offboarding_tasks.offboarding_employee_id = offboarding_employees.id
          AND offboarding_tasks.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE onboarding_employees SET company_id = employees.company_id
        FROM employees WHERE onboarding_employees.employee_id = employees.id AND onboarding_employees.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE onboarding_tasks SET company_id = onboarding_employees.company_id
        FROM onboarding_employees WHERE onboarding_tasks.onboarding_employee_id = onboarding_employees.id
          AND onboarding_tasks.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE payrolls SET company_id = employees.company_id
        FROM employees WHERE payrolls.employee_id = employees.id AND payrolls.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE performance_goals SET company_id = employees.company_id
        FROM employees WHERE performance_goals.employee_id = employees.id AND performance_goals.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE performance_reviews SET company_id = employees.company_id
        FROM employees WHERE performance_reviews.employee_id = employees.id AND performance_reviews.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE policy_documents SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE recognitions SET company_id = employees.company_id
        FROM employees WHERE recognitions.received_by_id = employees.id AND recognitions.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE salary_structures SET company_id = employees.company_id
        FROM employees WHERE salary_structures.employee_id = employees.id AND salary_structures.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE sla_workflows SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE ticket_comments SET company_id = helpdesk_tickets.company_id
        FROM helpdesk_tickets WHERE ticket_comments.helpdesk_ticket_id = helpdesk_tickets.id
          AND ticket_comments.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE timesheets SET company_id = employees.company_id
        FROM employees WHERE timesheets.employee_id = employees.id AND timesheets.company_id IS NULL;
      SQL

      # Polymorphic pending_tasks: leave_requests, interviews, etc.
      execute <<~SQL.squish
        UPDATE pending_tasks SET company_id = leave_requests.company_id
        FROM leave_requests WHERE pending_tasks.taskable_type = 'LeaveRequest'
          AND pending_tasks.taskable_id = leave_requests.id AND pending_tasks.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE pending_tasks SET company_id = interviews.company_id
        FROM interviews WHERE pending_tasks.taskable_type = 'Interview'
          AND pending_tasks.taskable_id = interviews.id AND pending_tasks.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE pending_tasks SET company_id = employees.company_id
        FROM employees WHERE pending_tasks.taskable_type = 'Employee'
          AND pending_tasks.taskable_id = employees.id AND pending_tasks.company_id IS NULL;
      SQL
      execute <<~SQL.squish
        UPDATE pending_tasks SET company_id = #{dc_id} WHERE company_id IS NULL;
      SQL
    end

    say_with_time "Create company memberships for existing users" do
      execute <<~SQL.squish
        INSERT INTO company_memberships (company_id, user_id, status, created_at, updated_at)
        SELECT employees.company_id, users.id, 'active', NOW(), NOW()
        FROM users
        INNER JOIN employees ON employees.id = users.employee_id
        ON CONFLICT (company_id, user_id) DO NOTHING;
      SQL
      execute <<~SQL.squish
        INSERT INTO company_memberships (company_id, user_id, status, created_at, updated_at)
        SELECT #{dc_id}, users.id, 'active', NOW(), NOW()
        FROM users
        WHERE users.id NOT IN (SELECT user_id FROM company_memberships)
        ON CONFLICT (company_id, user_id) DO NOTHING;
      SQL
    end

    remove_index :employees, name: "index_employees_on_email"
    add_index :employees, [ :company_id, :email ], unique: true

    remove_index :channels, name: "index_channels_on_channel_type_and_name"
    add_index :channels, [ :company_id, :channel_type, :name ], unique: true

    tenant_tables.each do |table|
      change_column_null "#{table}", :company_id, false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Multitenancy migration cannot be safely reversed"
  end
end
