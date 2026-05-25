class AddCareersBrandingToCompanies < ActiveRecord::Migration[8.1]
  def up
    add_column :companies, :careers_slug, :string
    add_column :companies, :logo, :string

    Company.reset_column_information
    Company.find_each do |company|
      base = company.name.to_s.parameterize.presence || "company"
      slug = base
      suffix = 0
      while Company.where.not(id: company.id).exists?(careers_slug: slug)
        suffix += 1
        slug = "#{base}-#{suffix}"
      end
      company.update_columns(careers_slug: slug)
    end

    add_index :companies, :careers_slug, unique: true
  end

  def down
    remove_index :companies, :careers_slug
    remove_column :companies, :logo
    remove_column :companies, :careers_slug
  end
end
