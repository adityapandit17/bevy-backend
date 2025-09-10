class BirthdaysController < ApplicationController
  before_action :authenticate_user!

  # GET /birthdays/today
  def today
    @birthdays = Employee.active.birthday_today.includes(:department)
    render json: format_birthdays(@birthdays, "today")
  end

  # GET /birthdays/this_week
  def this_week
    @birthdays = Employee.active.birthday_this_week.includes(:department)
    render json: format_birthdays(@birthdays, "this_week")
  end

  # GET /birthdays/this_month
  def this_month
    @birthdays = Employee.active.birthday_this_month.includes(:department)
    render json: format_birthdays(@birthdays, "this_month")
  end

  # GET /birthdays/upcoming
  def upcoming
    # Get birthdays for the next 30 days
    upcoming_birthdays = []

    (0..29).each do |day_offset|
      date = Date.current + day_offset.days
      birthdays_on_date = Employee.active.where(
        "strftime('%m-%d', date_of_birth) = ?",
        date.strftime("%m-%d")
      ).includes(:department)

      if birthdays_on_date.any?
        upcoming_birthdays << {
          date: date.strftime("%Y-%m-%d"),
          day_name: date.strftime("%A"),
          employees: format_birthday_employees(birthdays_on_date)
        }
      end
    end

    render json: {
      upcoming_birthdays: upcoming_birthdays,
      total_count: upcoming_birthdays.sum { |day| day[:employees].count }
    }
  end

  private

  def format_birthdays(employees, period)
    {
      period: period,
      count: employees.count,
      employees: format_birthday_employees(employees)
    }
  end

  def format_birthday_employees(employees)
    employees.map do |employee|
      {
        id: employee.id,
        name: employee.name,
        first_name: employee.first_name,
        last_name: employee.last_name,
        email: employee.email,
        department: employee.department.name,
        designation: employee.designation,
        date_of_birth: employee.date_of_birth,
        birthday_formatted: employee.birthday_formatted,
        age: employee.age,
        next_birthday: employee.next_birthday,
        days_until_birthday: employee.days_until_birthday,
        avatar_url: employee.avatar_url
      }
    end
  end
end
