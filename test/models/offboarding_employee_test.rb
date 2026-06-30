require "test_helper"

class OffboardingEmployeeTest < ActiveSupport::TestCase
  setup do
    @employee = create_test_employee(
      email: "offboard.me@example.com",
      status: "active"
    )
    @user = ActsAsTenant.with_tenant(companies(:one)) do
      User.create!(
        email: @employee.email,
        password: "Password123!",
        first_name: @employee.first_name,
        last_name: @employee.last_name,
        status: "active",
        employee: @employee,
        company: companies(:one)
      )
    end
    @offboarding = ActsAsTenant.with_tenant(companies(:one)) do
      OffboardingEmployee.create!(
        employee: @employee,
        last_working_day: 2.weeks.from_now.to_date,
        status: "pending",
        progress: 0,
        start_date: Date.current,
        company: companies(:one)
      )
    end
  end

  test "completing offboarding deactivates employee and revokes portal access" do
    ActsAsTenant.with_tenant(companies(:one)) do
      @offboarding.update!(status: "completed")
    end

    @employee.reload
    @user.reload

    assert_equal "inactive", @employee.status
    assert_equal "inactive", @user.status
    assert_nil JwtService.verify_token(JwtService.generate_token(@user))
  end

  test "completing all offboarding tasks deactivates employee and revokes portal access" do
    ActsAsTenant.with_tenant(companies(:one)) do
      @offboarding.offboarding_tasks.create!(
        title: "Return laptop",
        description: "Return company laptop",
        category: "Equipment",
        priority: "high",
        due_date: 1.week.from_now.to_date,
        assigned_to: "IT Department",
        company: companies(:one)
      )

      @offboarding.offboarding_tasks.each do |task|
        task.update!(is_completed: true)
      end
    end

    @offboarding.reload
    @employee.reload
    @user.reload

    assert_equal "completed", @offboarding.status
    assert_equal 100, @offboarding.progress
    assert_equal "inactive", @employee.status
    assert_equal "inactive", @user.status
  end

  test "pending offboarding does not deactivate employee or user" do
    @employee.reload
    @user.reload

    assert_equal "pending", @offboarding.status
    assert_equal "active", @employee.status
    assert_equal "active", @user.status
  end

  test "cancelled offboarding does not deactivate employee or user" do
    ActsAsTenant.with_tenant(companies(:one)) do
      @offboarding.update!(status: "cancelled")
    end

    @employee.reload
    @user.reload

    assert_equal "active", @employee.status
    assert_equal "active", @user.status
  end
end
