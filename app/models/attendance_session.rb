class AttendanceSession < ApplicationRecord
  belongs_to :attendance_record

  before_save :calculate_session_hours
  after_save :update_attendance_record_working_hours

  def calculate_session_hours
    return unless check_in.present? && check_out.present?

    # Calculate hours
    hours = (check_out - check_in) / 3600.0

    # Database has precision 5, scale 2 (can store up to 999.99)
    # Round to 2 decimal places, but ensure we don't lose very short sessions
    # For sessions less than 1 minute (0.0167 hours), store as 0.01 to indicate a valid session
    if hours > 0 && hours < 0.0167
      self.session_hours = 0.01
    else
      # Round to 2 decimal places for storage
      self.session_hours = hours.round(2)
    end
  end

  private

  def update_attendance_record_working_hours
    # Update the parent attendance record's working_hours whenever a session is saved
    # This ensures working_hours is always the sum of all session_hours
    return unless attendance_record.present?

    # Reload the record to get the latest sessions (including the one just saved)
    attendance_record.reload

    # Calculate total hours from all sessions
    total_hours = attendance_record.attendance_sessions.sum(:session_hours) || 0.0
    rounded_total = total_hours.round(2)

    # Update the record's working_hours using update_column to avoid triggering callbacks
    # This prevents infinite loops since update_column bypasses validations and callbacks
    attendance_record.update_column(:working_hours, rounded_total)

    # Now trigger status update by saving (this will run determine_status_from_sessions callback)
    # The update_working_hours_from_sessions callback will also run but will set the same value
    # We use update_columns to set working_hours first, then save to trigger status update
    attendance_record.save(validate: false)
  end
end
