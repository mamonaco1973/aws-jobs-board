require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module Jobboard
  class Application < Rails::Application
    config.load_defaults 7.1

    # Background jobs via Sidekiq
    config.active_job.queue_adapter = :sidekiq

    # File uploads go to S3 via ActiveStorage
    config.active_storage.service = :amazon

    # All logs go to stdout — ECS / CloudWatch picks them up
    config.log_level = :info
  end
end
