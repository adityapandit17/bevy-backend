class AddUniqueIndexToAttendanceRecordsOnEmployeeAndDate < ActiveRecord::Migration[8.0]
  def up
    # For each employee/date combination with duplicates, keep the latest record (most recent created_at)
    # and move all sessions from other records to it, then delete the duplicates
    
    # Find all duplicate groups - get the latest record ID for each employee/date combination
    duplicate_data = execute <<-SQL
      SELECT 
        ar1.employee_id,
        ar1.date,
        MAX(ar1.id) as keep_id
      FROM attendance_records ar1
      WHERE (ar1.employee_id, ar1.date) IN (
        SELECT employee_id, date
        FROM attendance_records
        GROUP BY employee_id, date
        HAVING COUNT(*) > 1
      )
      AND ar1.id = (
        SELECT id FROM attendance_records ar2
        WHERE ar2.employee_id = ar1.employee_id
        AND ar2.date = ar1.date
        ORDER BY ar2.created_at DESC, ar2.id DESC
        LIMIT 1
      )
      GROUP BY ar1.employee_id, ar1.date
    SQL
    
    # Process each duplicate group
    duplicate_data.each do |row|
      # SQLite returns results as arrays, PostgreSQL as hashes
      employee_id = row.is_a?(Hash) ? row['employee_id'] : row[0]
      date = row.is_a?(Hash) ? row['date'] : row[1]
      keep_id = row.is_a?(Hash) ? row['keep_id'] : row[2]
      
      # Find all duplicate record IDs (excluding the one we're keeping)
      duplicate_ids = execute <<-SQL
        SELECT id FROM attendance_records
        WHERE employee_id = #{quote(employee_id)}
        AND date = #{quote(date)}
        AND id != #{keep_id}
      SQL
      
      duplicate_ids.each do |dup_row|
        dup_id = dup_row.is_a?(Hash) ? dup_row['id'] : dup_row[0]
        
        # Move all sessions from this duplicate record to the one we're keeping
        execute <<-SQL
          UPDATE attendance_sessions
          SET attendance_record_id = #{keep_id}
          WHERE attendance_record_id = #{dup_id}
        SQL
        
        # Delete the duplicate record
        execute <<-SQL
          DELETE FROM attendance_records WHERE id = #{dup_id}
        SQL
      end
    end
    
    # Add unique index on (employee_id, date)
    add_index :attendance_records, [:employee_id, :date], unique: true, name: 'index_attendance_records_on_employee_id_and_date_unique'
  rescue => e
    # If consolidation fails, log the error but still try to add the index
    # The uniqueness validation in the model will prevent new duplicates
    Rails.logger.error "Error consolidating duplicate attendance records: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Still add the index - it will fail if duplicates still exist, which is fine
    # We can handle duplicates manually if needed
    begin
      add_index :attendance_records, [:employee_id, :date], unique: true, name: 'index_attendance_records_on_employee_id_and_date_unique'
    rescue => index_error
      Rails.logger.error "Could not add unique index due to existing duplicates. Please manually resolve duplicates first."
      raise index_error
    end
  end

  def down
    remove_index :attendance_records, name: 'index_attendance_records_on_employee_id_and_date_unique'
  end
end
