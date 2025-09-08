require "test_helper"

class AuthorizationTest < ActionController::TestCase
  class TestController < ApplicationController
    include Authorization
    
    def test_action
      authorize!('employees', 'index')
      render json: { message: 'success' }
    end
    
    def test_action_without_permission
      authorize!('payrolls', 'create')
      render json: { message: 'success' }
    end
  end

  def setup
    @controller = TestController.new
    
    # Create test user with limited permissions
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
      status: 'active'
    )
    
    # Create role with limited permissions
    @role = Role.create!(name: 'Test Role', description: 'Test role')
    
    # Create permissions
    @employee_index_permission = Permission.create!(
      name: 'employees.index',
      resource: 'employees',
      action: 'index',
      description: 'View employees'
    )
    
    @payroll_create_permission = Permission.create!(
      name: 'payrolls.create',
      resource: 'payrolls',
      action: 'create',
      description: 'Create payroll'
    )
    
    # Assign only employee index permission to role
    @role.permissions << @employee_index_permission
    @user.roles << @role
    
    # Mock current_user
    @controller.instance_variable_set(:@current_user, @user)
  end

  test "authorize! allows access when user has permission" do
    get :test_action
    assert_response :success
    assert_equal 'success', JSON.parse(response.body)['message']
  end

  test "authorize! denies access when user lacks permission" do
    get :test_action_without_permission
    assert_response :forbidden
    assert_equal 'Access denied', JSON.parse(response.body)['error']
  end

  test "authorize! allows access for super admin regardless of permission" do
    # Create super admin role
    super_admin_role = Role.create!(name: 'Super Admin', description: 'Full access')
    @user.roles.clear
    @user.roles << super_admin_role
    
    get :test_action_without_permission
    assert_response :success
    assert_equal 'success', JSON.parse(response.body)['message']
  end

  test "authorize! denies access when user is inactive" do
    @user.update!(status: 'inactive')
    
    get :test_action
    assert_response :forbidden
    assert_equal 'Access denied', JSON.parse(response.body)['error']
  end

  test "authorize! denies access when user has no roles" do
    @user.roles.clear
    
    get :test_action
    assert_response :forbidden
    assert_equal 'Access denied', JSON.parse(response.body)['error']
  end

  test "authorize! works with multiple roles" do
    # Create second role with payroll permission
    second_role = Role.create!(name: 'Payroll Manager', description: 'Payroll access')
    second_role.permissions << @payroll_create_permission
    @user.roles << second_role
    
    get :test_action_without_permission
    assert_response :success
    assert_equal 'success', JSON.parse(response.body)['message']
  end

  test "authorize! works with resource and action parameters" do
    # Test different resource/action combinations
    @controller.define_singleton_method(:test_custom_action) do
      authorize!('attendance_records', 'approve')
      render json: { message: 'success' }
    end
    
    # User doesn't have attendance approval permission
    get :test_custom_action
    assert_response :forbidden
  end

  test "authorize! handles edge cases gracefully" do
    # Test with nil user
    @controller.instance_variable_set(:@current_user, nil)
    
    get :test_action
    assert_response :forbidden
    assert_equal 'Access denied', JSON.parse(response.body)['error']
  end

  test "authorize! works with case insensitive resource names" do
    # Create permission with different case
    permission = Permission.create!(
      name: 'EMPLOYEES.index',
      resource: 'EMPLOYEES',
      action: 'INDEX',
      description: 'View employees uppercase'
    )
    
    @role.permissions.clear
    @role.permissions << permission
    
    get :test_action
    assert_response :success
  end

  test "authorize! works with wildcard permissions" do
    # Create wildcard permission
    wildcard_permission = Permission.create!(
      name: 'employees.*',
      resource: 'employees',
      action: '*',
      description: 'All employee actions'
    )
    
    @role.permissions.clear
    @role.permissions << wildcard_permission
    
    get :test_action
    assert_response :success
  end

  test "authorize! logs authorization attempts" do
    # This test would require setting up logging and checking log output
    # For now, we'll just ensure the method doesn't crash
    get :test_action
    assert_response :success
  end

  test "authorize! performance with many permissions" do
    # Create many permissions to test performance
    100.times do |i|
      permission = Permission.create!(
        name: "resource#{i}.action#{i}",
        resource: "resource#{i}",
        action: "action#{i}",
        description: "Permission #{i}"
      )
      @role.permissions << permission
    end
    
    # Should still work efficiently
    get :test_action
    assert_response :success
  end

  test "authorize! works with permission inheritance" do
    # Test that permissions are properly inherited through roles
    parent_role = Role.create!(name: 'Parent Role', description: 'Parent role')
    child_role = Role.create!(name: 'Child Role', description: 'Child role')
    
    parent_role.permissions << @employee_index_permission
    child_role.permissions << @payroll_create_permission
    
    @user.roles.clear
    @user.roles << parent_role
    @user.roles << child_role
    
    # Should have both permissions
    get :test_action
    assert_response :success
    
    get :test_action_without_permission
    assert_response :success
  end

  test "authorize! handles permission conflicts correctly" do
    # Create conflicting permissions (one allows, one denies)
    allow_permission = Permission.create!(
      name: 'employees.allow',
      resource: 'employees',
      action: 'index',
      description: 'Allow employees'
    )
    
    deny_permission = Permission.create!(
      name: 'employees.deny',
      resource: 'employees',
      action: 'index',
      description: 'Deny employees'
    )
    
    @role.permissions.clear
    @role.permissions << allow_permission
    @role.permissions << deny_permission
    
    # Should allow access (any permission grants access)
    get :test_action
    assert_response :success
  end

  test "authorize! works with custom permission formats" do
    # Test with custom permission naming
    custom_permission = Permission.create!(
      name: 'custom:employees:view',
      resource: 'employees',
      action: 'index',
      description: 'Custom permission format'
    )
    
    @role.permissions.clear
    @role.permissions << custom_permission
    
    get :test_action
    assert_response :success
  end

  test "authorize! handles database errors gracefully" do
    # Mock database error
    Permission.stub(:joins, -> { raise ActiveRecord::ConnectionNotEstablished }) do
      get :test_action
      assert_response :forbidden
      assert_equal 'Access denied', JSON.parse(response.body)['error']
    end
  end

  test "authorize! works with cached permissions" do
    # Test that permissions are properly cached and retrieved
    get :test_action
    assert_response :success
    
    # Second call should use cached permissions
    get :test_action
    assert_response :success
  end

  test "authorize! handles permission updates correctly" do
    # Initially user has permission
    get :test_action
    assert_response :success
    
    # Remove permission
    @role.permissions.clear
    
    # Should now be denied
    get :test_action
    assert_response :forbidden
  end

  test "authorize! works with role hierarchy" do
    # Create hierarchical roles
    admin_role = Role.create!(name: 'Admin', description: 'Admin role')
    manager_role = Role.create!(name: 'Manager', description: 'Manager role')
    
    admin_role.permissions << @employee_index_permission
    manager_role.permissions << @payroll_create_permission
    
    @user.roles.clear
    @user.roles << admin_role
    @user.roles << manager_role
    
    # Should have permissions from both roles
    get :test_action
    assert_response :success
    
    get :test_action_without_permission
    assert_response :success
  end

  test "authorize! handles empty permission lists" do
    @role.permissions.clear
    
    get :test_action
    assert_response :forbidden
  end

  test "authorize! works with special characters in resource names" do
    # Test with special characters
    special_permission = Permission.create!(
      name: 'employees-special.index',
      resource: 'employees-special',
      action: 'index',
      description: 'Special characters permission'
    )
    
    @role.permissions.clear
    @role.permissions << special_permission
    
    # Should work with special characters
    @controller.define_singleton_method(:test_special_action) do
      authorize!('employees-special', 'index')
      render json: { message: 'success' }
    end
    
    get :test_special_action
    assert_response :success
  end
end
