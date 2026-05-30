# frozen_string_literal: true

# macOS + pg can segfault when Solid Queue forks worker processes.
# Default to async supervisor in development unless explicitly overridden.
if Rails.env.development?
  ENV["SOLID_QUEUE_SUPERVISOR_MODE"] ||= "async"
end
