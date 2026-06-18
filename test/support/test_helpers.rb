module TestHelpers
  # Helper methods for creating test data
  def create_test_employee(attributes = {})
    company = attributes.delete(:company) || companies(:one)
    default_attributes = {
      first_name: "Test",
      last_name: "Employee",
      email: "test.employee@example.com",
      phone: "1234567890",
      department_id: departments(:one).id,
      designation: "Software Engineer",
      date_of_joining: Date.current,
      status: "active",
      company: company
    }

    ActsAsTenant.with_tenant(company) do
      Employee.create!(default_attributes.merge(attributes))
    end
  end

  def create_test_department(attributes = {})
    company = attributes.delete(:company) || companies(:one)
    default_attributes = {
      name: "Test Department #{SecureRandom.hex(3)}",
      company: company
    }

    ActsAsTenant.with_tenant(company) do
      Department.create!(default_attributes.merge(attributes))
    end
  end

  def create_test_asset(attributes = {})
    company = attributes.delete(:company) || companies(:one)
    default_attributes = {
      name: "Test Asset",
      asset_type: "laptop",
      serial_number: "TEST#{SecureRandom.hex(4)}",
      brand: "Test Brand",
      model: "Test Model",
      purchase_date: Date.current,
      purchase_cost: 1000.00,
      current_value: 1000.00,
      status: "available",
      location: "Test Location",
      department: "Engineering",
      condition: "good",
      company: company
    }

    ActsAsTenant.with_tenant(company) do
      Asset.create!(default_attributes.merge(attributes))
    end
  end

  def create_test_leave_request(attributes = {})
    company = attributes.delete(:company) || companies(:one)
    default_attributes = {
      employee_id: employees(:one).id,
      leave_type: "annual",
      start_date: Date.current + 1.week,
      end_date: Date.current + 2.weeks,
      reason: "Test leave",
      status: "pending",
      company: company
    }

    ActsAsTenant.with_tenant(company) do
      LeaveRequest.create!(default_attributes.merge(attributes))
    end
  end

  # Helper methods for API testing
  def json_response
    JSON.parse(@response.body)
  end

  def assert_json_success
    assert_response :success
    assert_equal "application/json", @response.media_type
  end

  def assert_json_created
    assert_response :created
    assert_equal "application/json", @response.media_type
  end

  def assert_json_unprocessable_entity
    assert_response :unprocessable_entity
    assert_equal "application/json", @response.media_type
  end

  def assert_json_not_found
    assert_response :not_found
    assert_equal "application/json", @response.media_type
  end

  def assert_json_bad_request
    assert_response :bad_request
  end

  # Helper methods for validation testing
  def assert_validation_error(field, error_message)
    assert_not @response.successful?
    json_response = JSON.parse(@response.body)
    assert_includes json_response["errors"], error_message
  end

  def assert_required_field(field)
    assert_validation_error(field, "#{field.to_s.humanize} can't be blank")
  end

  def assert_inclusion_error(field, value)
    assert_validation_error(field, "#{field.to_s.humanize} is not included in the list")
  end

  # Helper methods for database testing
  def assert_database_change(model, count_change = 1, &block)
    assert_difference("#{model}.count", count_change, &block)
  end

  def assert_no_database_change(model, &block)
    assert_no_difference("#{model}.count", &block)
  end

  # Helper methods for date testing
  def assert_date_format(date_string, expected_format = "%Y-%m-%d")
    assert Date.parse(date_string)
    assert_equal expected_format, Date.parse(date_string).strftime(expected_format)
  end

  def assert_date_range(start_date, end_date, expected_days)
    actual_days = (end_date - start_date).to_i + 1
    assert_equal expected_days, actual_days
  end

  # Helper methods for email testing
  def assert_valid_email(email)
    assert_match URI::MailTo::EMAIL_REGEXP, email
  end

  def assert_invalid_email(email)
    assert_no_match URI::MailTo::EMAIL_REGEXP, email
  end

  # Helper methods for phone number testing
  def assert_valid_phone(phone)
    assert_match /\A[\d\s\(\)\+\-\.]+\z/, phone
  end

  # Helper methods for status testing
  def assert_status_transition(model, from_status, to_status)
    model.update!(status: from_status)
    assert_equal from_status, model.reload.status

    model.update!(status: to_status)
    assert_equal to_status, model.reload.status
  end

  # Helper methods for scope testing
  def assert_scope_includes(model_class, scope_name, expected_record, *args)
    scope_result = model_class.send(scope_name, *args)
    assert_includes scope_result, expected_record
  end

  def assert_scope_excludes(model_class, scope_name, unexpected_record, *args)
    scope_result = model_class.send(scope_name, *args)
    assert_not_includes scope_result, unexpected_record
  end

  # Helper methods for association testing
  def assert_association_exists(model, association_name)
    assert_respond_to model, association_name
  end

  def assert_association_type(model, association_name, expected_type)
    association = model.class.reflect_on_association(association_name)
    assert_not_nil association
    assert_equal expected_type, association.macro
  end

  # Helper methods for callback testing
  def assert_callback_executed(model_class, callback_type, callback_method)
    callbacks = model_class._callbacks[callback_type]
    callback_names = callbacks.map(&:filter)
    assert_includes callback_names, callback_method
  end

  # Helper methods for performance testing
  def assert_query_count(expected_count, &block)
    count = 0
    counter = ->(name, started, finished, unique_id, payload) {
      count += 1 unless payload[:name].in? %w[ CACHE SCHEMA ]
    }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    assert_equal expected_count, count
  end

  # Helper methods for concurrent testing
  def run_concurrent_operations(operation_count, &block)
    threads = []
    results = []

    operation_count.times do |i|
      threads << Thread.new do
        result = block.call(i)
        results << result
      end
    end

    threads.each(&:join)
    results
  end

  # Helper methods for file upload testing
  def create_test_file(filename, content = "test content")
    file = Tempfile.new([ filename, File.extname(filename) ])
    file.write(content)
    file.rewind
    file
  end

  # Helper methods for time testing
  def travel_to_time(time, &block)
    Time.use_zone(Time.zone) do
      travel_to(time) do
        block.call
      end
    end
  end

  def freeze_time(&block)
    travel_to(Time.current, &block)
  end

  # Helper methods for random data generation
  def random_email
    "test#{SecureRandom.hex(4)}@example.com"
  end

  def random_phone
    "+1-#{rand(100..999)}-#{rand(100..999)}-#{rand(1000..9999)}"
  end

  def random_serial_number
    "SN#{SecureRandom.hex(6).upcase}"
  end

  # Helper methods for bulk operations testing
  def create_bulk_employees(count, base_attributes = {})
    employees = []
    count.times do |i|
      attributes = base_attributes.merge(
        first_name: "Bulk#{i}",
        last_name: "Employee#{i}",
        email: "bulk#{i}@example.com",
        phone: "#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}#{i}"
      )
      employees << Employee.create!(attributes)
    end
    employees
  end

  def create_bulk_assets(count, base_attributes = {})
    assets = []
    count.times do |i|
      attributes = base_attributes.merge(
        name: "Bulk Asset #{i}",
        serial_number: "BULK#{i}123456789",
        brand: "Bulk Brand #{i}",
        model: "Bulk Model #{i}"
      )
      assets << Asset.create!(attributes)
    end
    assets
  end

  # Helper methods for error testing
  def assert_error_response(error_type, error_message = nil)
    case error_type
    when :not_found
      assert_json_not_found
    when :unprocessable_entity
      assert_json_unprocessable_entity
    when :bad_request
      assert_json_bad_request
    end

    if error_message
      json_response = JSON.parse(@response.body)
      assert_includes json_response["errors"], error_message
    end
  end

  # Helper methods for pagination testing
  def assert_paginated_response(response_data, expected_count, page = 1, per_page = 25)
    assert_not_nil response_data["data"]
    assert_not_nil response_data["pagination"]
    assert_equal expected_count, response_data["pagination"]["total_count"]
    assert_equal page, response_data["pagination"]["current_page"]
    assert_equal per_page, response_data["pagination"]["per_page"]
  end

  # Helper methods for search testing
  def assert_search_results(response_data, search_term, expected_count = nil)
    assert_not_nil response_data["results"]
    assert_not_nil response_data["search_term"]
    assert_equal search_term, response_data["search_term"]

    if expected_count
      assert_equal expected_count, response_data["total_count"]
    end
  end

  # Helper methods for filter testing
  def assert_filtered_results(response_data, filters, expected_count = nil)
    assert_not_nil response_data["results"]
    assert_not_nil response_data["filters"]

    filters.each do |key, value|
      assert_equal value, response_data["filters"][key.to_s]
    end

    if expected_count
      assert_equal expected_count, response_data["total_count"]
    end
  end

  # Helper methods for statistics testing
  def assert_statistics_response(response_data, expected_keys)
    expected_keys.each do |key|
      assert_not_nil response_data[key], "Missing statistics key: #{key}"
    end
  end

  # Helper methods for export testing
  def assert_export_response(content_type, filename = nil)
    assert_response :success
    assert_equal content_type, @response.content_type

    if filename
      assert_equal "attachment; filename=\"#{filename}\"", @response.headers["Content-Disposition"]
    end
  end

  # Helper methods for webhook testing
  def assert_webhook_payload(payload, expected_event, expected_data)
    assert_equal expected_event, payload["event"]
    assert_equal expected_data, payload["data"]
    assert_not_nil payload["timestamp"]
  end

  # Helper methods for cache testing
  def assert_cached_response(cache_key)
    assert Rails.cache.exist?(cache_key)
  end

  def assert_not_cached_response(cache_key)
    assert_not Rails.cache.exist?(cache_key)
  end

  # Helper methods for background job testing
  def assert_enqueued_job(job_class, &block)
    assert_enqueued_with(job: job_class, &block)
  end

  def assert_performed_job(job_class, &block)
    assert_performed_with(job: job_class, &block)
  end

  # Helper methods for mailer testing
  def assert_email_sent(to:, subject: nil, &block)
    assert_emails(1) do
      block.call
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal to, email.to.first

    if subject
      assert_equal subject, email.subject
    end
  end

  # JWT authentication helpers

  # Generate an auth header for the given user (or the default test admin)
  def auth_headers_for(user = nil)
    user ||= @auth_user
    token = JwtService.generate_token(user)
    { "Authorization" => "Bearer #{token}" }
  end

  # Create (or find) a super-admin test user with full permissions
  def find_or_create_test_admin
    company = companies(:one)
    user = User.unscoped.find_by(email: "test.admin@example.com", company_id: company.id)
    unless user
      ActsAsTenant.with_tenant(company) do
        user = User.create!(
          email: "test.admin@example.com",
          password: "Password123!",
          first_name: "Test",
          last_name: "Admin",
          status: "active",
          company: company
        )
      end
    end

    role = Role.find_or_create_by!(name: "Test Super Admin", company: company) do |r|
      r.description = "Full access role for tests"
    end

    unless user.roles.include?(role)
      user.roles << role
    end

    # Give the role all existing permissions (and create common ones if missing)
    %w[employees payrolls leave_requests attendance_records assets salary_structures
       departments events helpdesk_tickets knowledge_articles sla_workflows
       interviews candidates job_openings onboarding_employees onboarding_tasks
       performance_reviews performance_goals timesheets employee_documents
       employee_benefits employee_trainings ticket_comments maintenance_records
       asset_allocations users roles permissions settings reports leave_management].each do |resource|
      %w[index show create update destroy approve].each do |action|
        perm = Permission.find_or_create_by!(resource: resource, action: action) do |p|
          p.name = "#{resource}.#{action}"
          p.description = "#{action.capitalize} #{resource}"
        end
        RolePermission.find_or_create_by!(role: role, permission: perm)
      end
    end

    user
  end

  def sign_in_user(user)
    token = JwtService.generate_token(user)
    @auth_headers = { "Authorization" => "Bearer #{token}" }
  end

  def sign_out_user
    @auth_headers = {}
  end

  def assert_authorized(&block)
    assert_response_not_equal :unauthorized
  end

  def assert_not_authorized(&block)
    assert_response :unauthorized
  end
end

# Auto-inject JWT auth into all integration (controller) tests
class ActionDispatch::IntegrationTest
  include TestHelpers

  # BDD-style before_setup: runs before each test's own setup
  def before_setup
    super
    ActsAsTenant.current_tenant = companies(:one)
    @auth_user = find_or_create_test_admin
    @auth_user.update!(company: companies(:one)) if @auth_user.company_id != companies(:one).id
    @auth_headers = auth_headers_for(@auth_user)
  end

  def after_teardown
    ActsAsTenant.current_tenant = nil
    super
  end

  # Automatically inject auth + JSON accept headers into all HTTP methods
  %i[get post patch put delete].each do |method|
    define_method(method) do |path, **kwargs|
      default_headers = (@auth_headers || {}).merge("Accept" => "application/json")
      kwargs[:headers] = default_headers.merge(kwargs[:headers] || {})
      super(path, **kwargs)
    end
  end
end

class ActiveSupport::TestCase
  include TestHelpers
end
