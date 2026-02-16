# BevyHR Backend Test Suite

This directory contains comprehensive tests for the BevyHR (Human Resource Management System) backend application. The test suite covers all major components including models, controllers, and integration workflows.

## Test Structure

```
test/
├── controllers/           # Controller tests
├── models/               # Model tests
├── integration/          # Integration tests
├── support/             # Test helpers and utilities
├── fixtures/            # Test data fixtures
└── README.md           # This file
```

## Test Coverage

### Model Tests

#### Employee Model (`test/models/employee_test.rb`)
- **Validations**: All required fields, email format, status inclusion
- **Associations**: All has_many and belongs_to relationships
- **Scopes**: active, inactive, terminated, probation, by_department, by_designation, recent_hires, long_term
- **Instance Methods**: status checks, name formatting, tenure calculations, profile completion
- **Edge Cases**: Special characters, long text fields, date calculations

#### Asset Model (`test/models/asset_test.rb`)
- **Validations**: All required fields, asset type inclusion, serial number uniqueness
- **Associations**: Employee relationship, asset allocations, maintenance records
- **Scopes**: available, assigned, maintenance, retired, lost, by_type, by_department, by_condition
- **Instance Methods**: Status checks, depreciation calculations, maintenance tracking
- **Callbacks**: Depreciation calculation, status updates based on assignment
- **Edge Cases**: Different asset types, depreciation rates, maintenance scheduling

#### Department Model (`test/models/department_test.rb`)
- **Validations**: Name requirement
- **Associations**: All has_many relationships with other models
- **Basic Operations**: Create, update, delete operations
- **Edge Cases**: Special characters, long names, unicode characters

#### LeaveRequest Model (`test/models/leave_request_test.rb`)
- **Validations**: All required fields, date validation, status inclusion
- **Associations**: Employee relationship
- **Scopes**: approved, pending, rejected, by_type, by_employee, current_year, upcoming, past
- **Instance Methods**: Status checks, duration calculations, date formatting
- **Callbacks**: Days calculation, default status setting
- **Edge Cases**: Date boundaries, leap years, single-day leaves

### Controller Tests

#### EmployeesController (`test/controllers/employees_controller_test.rb`)
- **CRUD Operations**: Create, read, update, delete employees
- **Validation Testing**: Invalid data handling, duplicate emails, missing fields
- **Edge Cases**: Special characters, long text, concurrent operations
- **Error Handling**: Not found, bad request, malformed JSON
- **Response Format**: JSON response validation

#### AssetsController (`test/controllers/assets_controller_test.rb`)
- **CRUD Operations**: Create, read, update, delete assets
- **Filtering & Search**: Asset type, department, condition, status filters
- **Special Endpoints**: Stats, allocations, maintenance
- **Validation Testing**: Invalid data, duplicate serial numbers
- **Edge Cases**: Depreciation calculations, status transitions
- **Error Handling**: Comprehensive error scenarios

#### DepartmentsController (`test/controllers/departments_controller_test.rb`)
- **CRUD Operations**: Create, read, update, delete departments
- **Validation Testing**: Name requirements, special characters
- **Edge Cases**: Unicode characters, leading/trailing spaces
- **Error Handling**: Not found, bad request scenarios

#### LeaveRequestsController (`test/controllers/leave_requests_controller_test.rb`)
- **CRUD Operations**: Create, read, update, delete leave requests
- **Validation Testing**: Date validation, leave type inclusion
- **Status Transitions**: Pending → Approved → Rejected → Cancelled
- **Edge Cases**: Date boundaries, leap years, concurrent requests
- **Error Handling**: Invalid dates, missing fields

### Integration Tests

#### EmployeeWorkflow (`test/integration/employee_workflow_test.rb`)
- **Complete Onboarding Workflow**: Employee creation → Asset allocation → Leave requests
- **Employee Termination Workflow**: Asset deallocation → Status changes
- **Department Management Workflow**: Department creation → Employee assignment → Updates
- **Asset Lifecycle Workflow**: Creation → Assignment → Maintenance → Retirement
- **Leave Request Approval Workflow**: Multiple requests with different statuses
- **Concurrent Operations Workflow**: Thread-safe operations testing

### Test Helpers

#### TestHelpers (`test/support/test_helpers.rb`)
- **Data Creation**: Helper methods for creating test data
- **API Testing**: JSON response assertions, status code helpers
- **Validation Testing**: Error message assertions, field validation helpers
- **Database Testing**: Change assertions, query counting
- **Date Testing**: Format validation, range calculations
- **Performance Testing**: Query counting, concurrent operations
- **Utility Methods**: Random data generation, file handling

## Running Tests

### Run All Tests
```bash
cd backend
bin/rails test
```

### Run Specific Test Files
```bash
# Run model tests
bin/rails test test/models/

# Run controller tests
bin/rails test test/controllers/

# Run integration tests
bin/rails test test/integration/

# Run specific test file
bin/rails test test/models/employee_test.rb
```

### Run Specific Test Methods
```bash
# Run specific test method
bin/rails test test/models/employee_test.rb -n test_should_be_valid_with_valid_attributes
```

### Run Tests with Coverage
```bash
# If using SimpleCov gem
COVERAGE=true bin/rails test
```

## Test Data

### Fixtures
The test suite uses Rails fixtures for consistent test data:
- `employees.yml` - Sample employee data
- `departments.yml` - Sample department data
- `assets.yml` - Sample asset data
- `leave_requests.yml` - Sample leave request data

### Dynamic Test Data
Tests also create dynamic data using helper methods:
- `create_test_employee()` - Creates test employees
- `create_test_asset()` - Creates test assets
- `create_test_department()` - Creates test departments
- `create_test_leave_request()` - Creates test leave requests

## Test Categories

### Unit Tests
- **Model Tests**: Test individual model behavior, validations, associations, scopes
- **Helper Tests**: Test utility methods and helper functions

### Integration Tests
- **Controller Tests**: Test API endpoints, request/response handling
- **Workflow Tests**: Test complete business processes and workflows

### Performance Tests
- **Query Optimization**: Test database query efficiency
- **Concurrent Operations**: Test thread safety and race conditions
- **Bulk Operations**: Test handling of large datasets

### Edge Case Tests
- **Boundary Conditions**: Test limits and edge cases
- **Error Scenarios**: Test error handling and recovery
- **Data Validation**: Test input validation and sanitization

## Best Practices Implemented

### Test Organization
- Clear test method names describing the scenario being tested
- Logical grouping of related tests
- Consistent setup and teardown patterns

### Test Data Management
- Use of fixtures for consistent baseline data
- Helper methods for creating test-specific data
- Proper cleanup to avoid test interference

### Assertion Patterns
- Specific assertions for different types of validation
- Comprehensive error message testing
- JSON response structure validation

### Performance Considerations
- Query counting to ensure efficient database usage
- Concurrent operation testing for thread safety
- Bulk operation testing for scalability

## Coverage Areas

### Functional Coverage
- ✅ All CRUD operations for major entities
- ✅ Validation logic for all models
- ✅ Business logic and calculations
- ✅ Status transitions and workflows
- ✅ Search and filtering functionality

### Error Handling Coverage
- ✅ Invalid input validation
- ✅ Missing required fields
- ✅ Duplicate data handling
- ✅ Not found scenarios
- ✅ Malformed request handling

### Edge Case Coverage
- ✅ Special characters in text fields
- ✅ Long text handling
- ✅ Date boundary conditions
- ✅ Concurrent operations
- ✅ Unicode and internationalization

### Integration Coverage
- ✅ Complete business workflows
- ✅ Cross-entity relationships
- ✅ Data consistency across operations
- ✅ End-to-end process validation

## Maintenance

### Adding New Tests
1. Follow the existing naming conventions
2. Use the provided test helpers
3. Include both positive and negative test cases
4. Test edge cases and error conditions
5. Document any new test patterns

### Updating Tests
1. Update tests when changing model validations
2. Update tests when adding new controller actions
3. Update tests when changing business logic
4. Ensure all tests pass before committing changes

### Test Data Management
1. Keep fixtures minimal and focused
2. Use helper methods for complex test data
3. Clean up any test data created during tests
4. Avoid hardcoded values in tests

## Continuous Integration

The test suite is designed to run in CI/CD pipelines:
- Fast execution for quick feedback
- Comprehensive coverage for confidence
- Clear failure messages for debugging
- Parallel execution support

## Future Enhancements

### Planned Improvements
- [ ] Add system tests for UI interactions
- [ ] Add performance benchmarks
- [ ] Add security testing
- [ ] Add API documentation tests
- [ ] Add load testing scenarios

### Potential Additions
- [ ] Mock external service calls
- [ ] Add database transaction testing
- [ ] Add cache testing
- [ ] Add background job testing
- [ ] Add webhook testing

## Contributing

When contributing to the test suite:
1. Follow the existing patterns and conventions
2. Ensure all tests pass before submitting
3. Add tests for any new functionality
4. Update this documentation for significant changes
5. Consider the impact on test performance

## Support

For questions about the test suite:
1. Check this documentation first
2. Review existing test examples
3. Consult the Rails testing guide
4. Ask in the development team

---

*Last updated: January 2025*
*Test suite version: 1.0.0* 