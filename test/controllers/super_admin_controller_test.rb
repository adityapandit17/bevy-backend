require "test_helper"

class SuperAdminControllerTest < ActionDispatch::IntegrationTest
  test "should get dashboard" do
    get super_admin_dashboard_url
    assert_response :success
  end

  test "should get system_logs" do
    get super_admin_system_logs_url
    assert_response :success
  end

  test "should get audit_trails" do
    get super_admin_audit_trails_url
    assert_response :success
  end

  test "should get system_health" do
    get super_admin_system_health_url
    assert_response :success
  end

  test "should get database_management" do
    get super_admin_database_management_url
    assert_response :success
  end

  test "should get backup_restore" do
    get super_admin_backup_restore_url
    assert_response :success
  end

  test "should get user_activity" do
    get super_admin_user_activity_url
    assert_response :success
  end

  test "should get security_settings" do
    get super_admin_security_settings_url
    assert_response :success
  end

  test "should get system_configuration" do
    get super_admin_system_configuration_url
    assert_response :success
  end

  test "should get maintenance_mode" do
    get super_admin_maintenance_mode_url
    assert_response :success
  end
end
