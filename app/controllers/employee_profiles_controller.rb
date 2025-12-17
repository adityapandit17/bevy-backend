class EmployeeProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee
  before_action :authorize_employee_profile!

  def show
    render json: {
      employee: format_employee_data,
      overview: get_overview_data,
      job_details: get_job_details_data,
      time_off: get_time_off_data,
      pay_info: get_pay_info_data,
      documents: get_documents_data,
      performance: get_performance_data,
      timesheets: get_timesheets_data,
      benefits: get_benefits_data,
      training: get_training_data,
      assets: get_assets_data
    }
  end

  def overview
    render json: get_overview_data
  end

  def job_details
    render json: get_job_details_data
  end

  def time_off
    render json: get_time_off_data
  end

  def pay_info
    render json: get_pay_info_data
  end

  def documents
    render json: get_documents_data
  end

  def performance
    render json: get_performance_data
  end

  def timesheets
    render json: get_timesheets_data
  end

  def benefits
    render json: get_benefits_data
  end

  def training
    render json: get_training_data
  end

  def assets
    render json: get_assets_data
  end

  private

  def authorize_employee_profile!
    # Always allow users to view their own profile
    return if current_user&.employee_id == @employee.id

    # Otherwise require employees.show permission
    authorize!("employees", "show")
  end

  def set_employee
    @employee = Employee.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Employee not found" }, status: :not_found
  end

  def format_employee_data
    {
      id: @employee.id,
      name: @employee.name,
      email: @employee.email,
      phone: @employee.phone,
      position: @employee.position,
      department: @employee.department_name,
      hire_date: @employee.formatted_hire_date,
      tenure: @employee.tenure_summary,
      status: @employee.status,
      status_color: @employee.status_color,
      avatar_url: @employee.avatar_url,
      profile_completion: @employee.profile_completion_percentage
    }
  end

  def get_overview_data
    {
      employee: format_employee_data,
      stats: {
        total_leave_days: @employee.total_leave_days_this_year,
        pending_leave_requests: @employee.pending_leave_requests,
        total_assets: @employee.total_assets,
        assigned_assets: @employee.assigned_assets,
        total_documents: @employee.total_documents,
        active_documents: @employee.active_documents,
        expiring_documents: @employee.expiring_documents,
        average_rating: @employee.average_performance_rating,
        total_training_hours: @employee.total_training_hours,
        active_trainings: @employee.active_trainings,
        total_benefits_cost: @employee.total_benefits_cost,
        weekly_hours: @employee.weekly_hours_this_month
      },
      recent_activities: get_recent_activities
    }
  end

  def get_job_details_data
    {
      basic_info: {
        position: @employee.position,
        department: @employee.department_name,
        hire_date: @employee.formatted_hire_date,
        tenure: @employee.tenure_summary,
        status: @employee.status_label,
        status_color: @employee.status_color
      },
      contact_info: {
        email: @employee.email,
        phone: @employee.phone
      },
      employment_history: get_employment_history
    }
  end

  def get_time_off_data
    {
      summary: {
        total_days_this_year: @employee.total_leave_days_this_year,
        pending_requests: @employee.pending_leave_requests,
        leave_balance: calculate_leave_balance
      },
      leave_requests: @employee.leave_requests.limit(10).map do |request|
        {
          id: request.id,
          leave_type: request.leave_type_label,
          start_date: request.formatted_start_date,
          end_date: request.formatted_end_date,
          days: request.days,
          status: request.status,
          status_color: request.status_color,
          reason: request.reason
        }
      end
    }
  end

  def get_pay_info_data
    {
      current_salary: @employee.salary,
      salary_structure: @employee.salary_structures.first&.as_json(include: :employee),
      payroll_history: @employee.payrolls.limit(12).map do |payroll|
        {
          id: payroll.id,
          month: payroll.month,
          gross_salary: payroll.gross_salary,
          net_salary: payroll.net_salary,
          status: payroll.status
        }
      end
    }
  end

  def get_documents_data
    {
      summary: {
        total_documents: @employee.total_documents,
        active_documents: @employee.active_documents,
        expiring_soon: @employee.expiring_documents
      },
      documents: @employee.employee_documents.map do |doc|
        {
          id: doc.id,
          name: doc.name,
          document_type: doc.document_type_label,
          upload_date: doc.formatted_upload_date,
          expiry_date: doc.formatted_expiry_date,
          status: doc.status,
          status_color: doc.status_color,
          file_size: doc.file_size_formatted,
          uploaded_by: doc.uploaded_by
        }
      end
    }
  end

  def get_performance_data
    {
      summary: {
        average_rating: @employee.average_performance_rating,
        latest_review: @employee.latest_performance_review&.formatted_review_date
      },
      reviews: @employee.performance_reviews.recent.map do |review|
        {
          id: review.id,
          period: review.period,
          rating: review.rating,
          rating_description: review.rating_description,
          rating_color: review.rating_color,
          reviewer: review.reviewer,
          review_date: review.formatted_review_date,
          comments: review.comments
        }
      end,
      goals: @employee.performance_goals.recent.map do |goal|
        {
          id: goal.id,
          title: goal.title,
          description: goal.description,
          progress: goal.progress,
          status: goal.status,
          status_color: goal.status_color,
          due_date: goal.formatted_due_date,
          completion_status: goal.completion_status
        }
      end
    }
  end

  def get_timesheets_data
    {
      summary: {
        weekly_hours: @employee.weekly_hours_this_month,
        total_entries: @employee.timesheets.size,
        approved_entries: @employee.timesheets.approved.size
      },
      timesheets: @employee.timesheets.recent.limit(20).map do |timesheet|
        {
          id: timesheet.id,
          date: timesheet.formatted_date,
          hours: timesheet.hours_formatted,
          project: timesheet.project,
          task: timesheet.task,
          status: timesheet.status,
          status_color: timesheet.status_color,
          approved_by: timesheet.approved_by,
          notes: timesheet.notes
        }
      end
    }
  end

  def get_benefits_data
    {
      summary: {
        total_benefits: @employee.employee_benefits.size,
        active_benefits: @employee.employee_benefits.active.size,
        total_cost: @employee.total_benefits_cost
      },
      benefits: @employee.employee_benefits.map do |benefit|
        {
          id: benefit.id,
          name: benefit.name,
          benefit_type: benefit.benefit_type_label,
          provider: benefit.provider,
          coverage: benefit.coverage,
          start_date: benefit.formatted_start_date,
          end_date: benefit.formatted_end_date,
          status: benefit.status,
          status_color: benefit.status_color,
          cost: benefit.cost_formatted,
          annual_cost: benefit.annual_cost_formatted
        }
      end
    }
  end

  def get_training_data
    {
      summary: {
        total_trainings: @employee.employee_trainings.size,
        completed_trainings: @employee.employee_trainings.completed.size,
        active_trainings: @employee.active_trainings,
        total_hours: @employee.total_training_hours
      },
      trainings: @employee.employee_trainings.recent.map do |training|
        {
          id: training.id,
          name: training.name,
          training_type: training.training_type_label,
          provider: training.provider,
          start_date: training.formatted_start_date,
          end_date: training.formatted_end_date,
          status: training.status,
          status_color: training.status_color,
          progress: training.progress,
          cost: training.cost_formatted,
          skills: training.skills_list,
          certificate: training.certificate_url
        }
      end
    }
  end

  def get_assets_data
    {
      summary: {
        total_assets: @employee.total_assets,
        assigned_assets: @employee.assigned_assets
      },
      assets: @employee.assets.map do |asset|
        {
          id: asset.id,
          name: asset.name,
          asset_type: asset.asset_type,
          serial_number: asset.serial_number,
          brand: asset.brand,
          model: asset.model,
          status: asset.status,
          status_color: asset.status_color,
          condition: asset.condition,
          location: asset.location,
          purchase_date: asset.purchase_date&.strftime("%B %d, %Y"),
          current_value: asset.current_value
        }
      end,
      allocations: @employee.asset_allocations.recent.map do |allocation|
        {
          id: allocation.id,
          asset_name: allocation.asset_name,
          assigned_date: allocation.assigned_date&.strftime("%B %d, %Y"),
          return_date: allocation.return_date&.strftime("%B %d, %Y"),
          status: allocation.status,
          notes: allocation.notes
        }
      end
    }
  end

  def get_recent_activities
    activities = []

    # Add recent leave requests
    @employee.leave_requests.limit(5).each do |request|
      activities << {
        type: "leave_request",
        date: request.created_at,
        description: "Requested #{request.leave_type_label} leave",
        status: request.status
      }
    end

    # Add recent timesheets
    @employee.timesheets.limit(5).each do |timesheet|
      activities << {
        type: "timesheet",
        date: timesheet.created_at,
        description: "Logged #{timesheet.hours} hours for #{timesheet.project}",
        status: timesheet.status
      }
    end

    # Add recent performance reviews
    @employee.performance_reviews.limit(3).each do |review|
      activities << {
        type: "performance_review",
        date: review.review_date,
        description: "Performance review for #{review.period}",
        rating: review.rating
      }
    end

    # Sort by date and return top 10
    activities.sort_by { |activity| activity[:date] }.reverse.first(10)
  end

  def get_employment_history
    # For now, return basic employment info
    # This could be expanded to include promotions, transfers, etc.
    [ {
      position: @employee.position,
      department: @employee.department_name,
      start_date: @employee.formatted_hire_date,
      end_date: nil,
      status: @employee.status
    } ]
  end

  def calculate_leave_balance
    # This would typically come from company policy
    # For now, return a placeholder
    {
      annual: 20,
      sick: 10,
      personal: 5,
      used: @employee.total_leave_days_this_year,
      remaining: 35 - @employee.total_leave_days_this_year
    }
  end
end
