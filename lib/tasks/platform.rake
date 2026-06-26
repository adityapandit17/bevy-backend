# frozen_string_literal: true

namespace :platform do
  desc "Ensure default platform admin exists (idempotent — safe for production)"
  task ensure_default_admin: :environment do
    load Rails.root.join("db/seeds/platform_admin.rb")
  end
end
