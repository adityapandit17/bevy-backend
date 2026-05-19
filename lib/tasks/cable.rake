# frozen_string_literal: true

namespace :db do
  namespace :cable do
    desc "Create cable DB and load solid_cable schema (production)"
    task prepare: :environment do
      next unless Rails.env.production?

      config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cable")
      unless config
        puts "No cable database configured — skipping"
        next
      end

      ActiveRecord::Tasks::DatabaseTasks.create(config)
      schema_path = Rails.root.join("db/cable_schema.rb")
      ActiveRecord::Tasks::DatabaseTasks.load_schema(config, :ruby, schema_path)
      puts "Cable database schema loaded from #{schema_path}"
    end
  end
end
