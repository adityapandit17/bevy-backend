class PayrollMonth
  # Parse month input (Date, Time, or string like "November 2024", "2024-11", "november-2024")
  def self.parse(value)
    return value.to_date.beginning_of_month if value.respond_to?(:to_date)

    str = value.to_s.strip
    # Try YYYY-MM or YYYY/MM
    if str.match?(/\A\d{4}[-\/]\d{1,2}\z/)
      year, month = str.split(/[-\/]/).map(&:to_i)
      return Date.new(year, month, 1)
    end

    # Try "November 2024" or "november-2024"
    cleaned = str.tr("-", " ")
    begin
      parsed = Date.parse(cleaned)
      return parsed.beginning_of_month
    rescue ArgumentError
      raise ArgumentError, "Invalid payroll month: #{value}"
    end
  end

  def self.label(date)
    dt = parse(date)
    dt.strftime("%B %Y")
  end

  def self.range(date)
    dt = parse(date)
    dt.beginning_of_month..dt.end_of_month
  end

  # Count working days in the month.
  # When weekend_only is true, exclude Saturdays and Sundays; otherwise include all calendar days.
  def self.working_days(date, weekend_only: true)
    days = range(date).to_a
    weekend_only ? days.count { |d| weekday?(d) } : days.count
  end

  def self.weekday?(date)
    !(date.saturday? || date.sunday?)
  end
end

