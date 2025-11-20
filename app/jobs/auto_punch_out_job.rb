class AutoPunchOutJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting auto punch out job at #{Time.current}"
    result = AttendanceService.auto_punch_out_all_active_sessions
    Rails.logger.info "Auto punch out job completed: #{result[:message]}"
    result
  rescue => e
    Rails.logger.error "AutoPunchOutJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      message: "Job failed: #{e.message}"
    }
  end
end

