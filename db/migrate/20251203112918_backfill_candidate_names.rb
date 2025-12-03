class BackfillCandidateNames < ActiveRecord::Migration[8.0]
  def up
    Candidate.reset_column_information
    
    # For candidates with empty first_name and last_name, try to extract from email
    Candidate.where(first_name: '').or(Candidate.where(last_name: '')).or(Candidate.where(first_name: nil)).or(Candidate.where(last_name: nil)).find_each do |candidate|
      # Try to extract name from email (e.g., "sarah.wilson@email.com" -> "Sarah Wilson")
      if candidate.email.present?
        email_name = candidate.email.split('@').first
        if email_name.present?
          name_parts = email_name.split(/[._-]/)
          if name_parts.length >= 2
            candidate.update_columns(
              first_name: name_parts[0].capitalize,
              last_name: name_parts[1..-1].join(' ').capitalize
            )
          elsif name_parts.length == 1
            # If only one part, use it as first_name
            candidate.update_columns(
              first_name: name_parts[0].capitalize,
              last_name: ''
            )
          end
        end
      end
      
      # If still empty, set a default
      if candidate.first_name.blank? && candidate.last_name.blank?
        candidate.update_columns(
          first_name: 'Unknown',
          last_name: 'Candidate'
        )
      elsif candidate.first_name.blank?
        candidate.update_columns(first_name: 'Unknown')
      elsif candidate.last_name.blank?
        candidate.update_columns(last_name: 'Candidate')
      end
    end
  end

  def down
    # This migration is not reversible as we don't have the original data
  end
end

