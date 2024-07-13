# frozen_string_literal: true

require "bundler/setup"
require "coruscate"
require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require "active_support/testing/time_helpers"

RSpec.configure do |config|
  Dir["./spec/support/*.rb"].each { |file| require file }

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include ActiveSupport::Testing::TimeHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
