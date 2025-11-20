class AttendanceService
  def initialize(employee)
    @employee = employee
  end

  def clock_in
    ActiveRecord::Base.transaction do
      # Find or create record, ensuring status is set
      record = AttendanceRecord.find_or_create_by!(
        employee: @employee,
        date: Date.today
      ) do |r|
        r.status = "present"
      end
      
      # Update status if it's not present (in case record already existed)
      record.update!(status: "present") unless record.status == "present"

      # Check for active session using direct SQL query
      active_session = AttendanceSession
                        .where(attendance_record_id: record.id)
                        .where("check_out IS NULL")
                        .exists?
      
      if active_session
        return { error: "Already clocked in! Please clock out first." }
      end

      # Create session directly (not through association to avoid caching issues)
      check_in_time = Time.current
      session = AttendanceSession.create!(
        attendance_record_id: record.id,
        check_in: check_in_time
      )
      
      # Verify session was created
      unless session.persisted? && session.id.present?
        Rails.logger.error "Failed to create attendance session for employee #{@employee.id}, record #{record.id}. Errors: #{session.errors.full_messages.join(', ')}"
        raise ActiveRecord::RecordInvalid.new(session)
      end
      
      # Verify session exists in database
      session_count = AttendanceSession.where(attendance_record_id: record.id).count
      if session_count == 0
        Rails.logger.error "Session creation failed: Session #{session.id} was created but not found in database for record #{record.id}"
        raise "Session was not persisted to database"
      end
      
      Rails.logger.info "Clock in successful for employee #{@employee.id}. Created session #{session.id}. Total sessions: #{session_count}"
      
      # Reload record to get updated associations
      record.reload
      # Ensure status is set to present after session is created
      record.update!(status: "present") unless record.status == "present"
      record.reload
      record
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation error creating session: #{e.message}"
    { error: "Failed to create attendance session: #{e.record.errors.full_messages.join(', ')}" }
  rescue => e
    Rails.logger.error "Error in clock_in: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: "Failed to clock in: #{e.message}" }
  end

  def clock_out
    record = AttendanceRecord.find_by(employee: @employee, date: Date.today)
    
    if record.nil?
      return { error: "No attendance record found for today" }
    end
    
    Rails.logger.info "Clock out attempt for employee #{@employee.id}, record ID: #{record.id}"
    
    # Get all sessions for this record
    all_sessions = AttendanceSession.where(attendance_record_id: record.id).order(created_at: :desc)
    Rails.logger.info "Sessions for record #{record.id}: #{all_sessions.count}"
    
    # Log all sessions to see their state
    all_sessions.each do |s|
      Rails.logger.info "  Session #{s.id}: check_in=#{s.check_in}, check_out=#{s.check_out.inspect}, check_out.nil?=#{s.check_out.nil?}, check_out.class=#{s.check_out.class}"
    end
    
    # Find active session (no check_out)
    session = AttendanceSession
              .where(attendance_record_id: record.id)
              .where("check_out IS NULL")
              .order(created_at: :desc)
              .first
    
    # Fallback: Filter in Ruby (in case of any SQL issues)
    unless session
      Rails.logger.warn "SQL query didn't find session, trying Ruby filter..."
      session = all_sessions.find { |s| s.check_out.nil? || s.check_out.blank? }
    end
    
    unless session
      Rails.logger.error "Clock out failed for employee #{@employee.id}: No active session found after all attempts."
      Rails.logger.error "Record ID searched: #{record.id}, Total sessions for this record: #{all_sessions.count}"
      
      # Log all sessions
      all_sessions.each do |s|
        Rails.logger.error "  Session #{s.id}: check_in=#{s.check_in}, check_out=#{s.check_out.inspect}, check_out.nil?=#{s.check_out.nil?}, check_out.blank?=#{s.check_out.blank?}"
      end
      
      if all_sessions.count == 0
        Rails.logger.error "Data inconsistency detected: No sessions found for employee #{@employee.id} today."
        return { 
          error: "No active session found. It appears your punch-in session was not properly recorded. Please punch in again.",
          code: "NO_SESSION",
          record_id: record.id
        }
      else
        # Sessions exist but all have check_out set
        return { 
          error: "No active session to clock out. All sessions are already closed.",
          code: "ALL_SESSIONS_CLOSED"
        }
      end
    end

    Rails.logger.info "Found active session #{session.id} for clock out"
    
    session.update!(check_out: Time.current)
    
    # Reload the session to get updated session_hours
    session.reload
    
    # The after_save callback on AttendanceSession will automatically update
    # the record's working_hours, but we'll also do it here to ensure it's updated
    # Reload record to get latest sessions
    record.reload
    
    # Calculate and update working hours from all sessions
    total_hours = record.attendance_sessions.sum(:session_hours) || 0.0
    record.update_column(:working_hours, total_hours.round(2))
    
    # Trigger status update
    record.save(validate: false)
    
    # Reload record to get updated associations
    record.reload
    record
  end
end
