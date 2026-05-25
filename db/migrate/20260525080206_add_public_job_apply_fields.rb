class AddPublicJobApplyFields < ActiveRecord::Migration[8.1]
  def up
    add_column :job_openings, :public_slug, :string
    add_reference :candidates, :job_opening, foreign_key: true, index: true

    JobOpening.reset_column_information
    JobOpening.find_each do |job|
      base = job.title.to_s.parameterize.presence || "job"
      slug = base
      suffix = 0
      while JobOpening.exists?(public_slug: slug)
        suffix += 1
        slug = "#{base}-#{suffix}"
      end
      job.update_column(:public_slug, slug)
    end

    add_index :job_openings, :public_slug, unique: true
  end

  def down
    remove_reference :candidates, :job_opening, foreign_key: true
    remove_index :job_openings, :public_slug
    remove_column :job_openings, :public_slug
  end
end
