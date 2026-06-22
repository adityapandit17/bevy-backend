module Reports
  class Period
    def self.resolve(params)
      if params[:start_date].present? && params[:end_date].present?
        return [ Date.parse(params[:start_date]), Date.parse(params[:end_date]) ]
      end

      today = Date.current
      case params[:period].to_s
      when "today"
        [ today, today ]
      when "week"
        [ today.beginning_of_week, today.end_of_week ]
      when "quarter"
        [ today.beginning_of_quarter, today.end_of_quarter ]
      when "year"
        [ today.beginning_of_year, today.end_of_year ]
      when "month"
        month_param = params[:month].presence
        if month_param&.match?(/\A\d{4}-\d{2}\z/)
          y, m = month_param.split("-").map(&:to_i)
          d = Date.new(y, m, 1)
          [ d.beginning_of_month, d.end_of_month ]
        else
          [ today.beginning_of_month, today.end_of_month ]
        end
      else
        [ today.beginning_of_month, today.end_of_month ]
      end
    rescue ArgumentError
      [ today.beginning_of_month, today.end_of_month ]
    end

    def self.label(start_date, end_date)
      return start_date.strftime("%B %d, %Y") if start_date == end_date

      "#{start_date.strftime('%b %d, %Y')} – #{end_date.strftime('%b %d, %Y')}"
    end
  end
end
