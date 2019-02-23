require "bundler/setup"
require "swaffle"
require "swaffle/spec/api_request_helper"
require "rspec/json_matcher"
require "byebug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.include Swaffle::Spec::ApiRequestHelper, type: :request
  config.include RSpec::JsonMatcher
end
