class UpdateCandidatesNameFields < ActiveRecord::Migration[8.0]
  def up
    # Add new columns
    add_column :candidates, :first_name, :string
    add_column :candidates, :last_name, :string
    add_column :candidates, :date_of_birth, :date

    # Migrate existing data: split name into first_name and last_name
    Candidate.reset_column_information
    Candidate.find_each do |candidate|
      if candidate.name.present?
        name_parts = candidate.name.split(' ', 2)
        candidate.update_columns(
          first_name: name_parts[0] || '',
          last_name: name_parts[1] || ''
        )
      end
    end

    # Remove the old name column
    remove_column :candidates, :name
  end

  def down
    # Add back the name column
    add_column :candidates, :name, :string

    # Migrate data back: combine first_name and last_name into name
    Candidate.reset_column_information
    Candidate.find_each do |candidate|
      full_name = [ candidate.first_name, candidate.last_name ].compact.join(' ').strip
      candidate.update_columns(name: full_name) if full_name.present?
    end

    # Remove the new columns
    remove_column :candidates, :first_name
    remove_column :candidates, :last_name
    remove_column :candidates, :date_of_birth
  end
end
