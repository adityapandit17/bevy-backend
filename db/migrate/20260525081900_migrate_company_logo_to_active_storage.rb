# frozen_string_literal: true

class MigrateCompanyLogoToActiveStorage < ActiveRecord::Migration[8.1]
  def up
    return unless column_exists?(:companies, :logo)

    Company.reset_column_information
    Company.where.not(logo: [ nil, "" ]).find_each do |company|
      path = Rails.root.join("storage", company.logo)
      next unless File.exist?(path)

      company.logo_attachment.attach(
        io: File.open(path),
        filename: File.basename(path),
        content_type: Rack::Mime.mime_type(File.extname(path)) || "image/png"
      )
    rescue StandardError => e
      Rails.logger.warn "[Company] Could not migrate logo for company #{company.id}: #{e.message}"
    end

    remove_column :companies, :logo, :string
  end

  def down
    add_column :companies, :logo, :string
  end
end
