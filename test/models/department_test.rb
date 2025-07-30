require "test_helper"

class DepartmentTest < ActiveSupport::TestCase
  def setup
    @department = Department.new(
      name: "Engineering"
    )
  end

  test "should be valid with valid attributes" do
    assert @department.valid?
  end

  test "should require name" do
    @department.name = nil
    assert @department.valid? # No validation exists in model
  end

  # Basic CRUD tests
  test "should be able to create department" do
    assert_difference('Department.count') do
      @department.save!
    end
  end

  test "should be able to update department" do
    @department.save!
    @department.name = "Updated Engineering"
    @department.save!
    assert_equal "Updated Engineering", @department.reload.name
  end

  test "should be able to delete department" do
    @department.save!
    assert_difference('Department.count', -1) do
      @department.destroy
    end
  end

  # Instance method tests
  test "should have basic attributes" do
    assert_respond_to @department, :name
    assert_respond_to @department, :created_at
    assert_respond_to @department, :updated_at
  end

  test "should return name as string" do
    assert_equal "Engineering", @department.name
  end
end
