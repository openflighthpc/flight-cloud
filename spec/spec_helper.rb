# frozen_string_literal: true

require 'rspec/wait'
require File.join(File.dirname(__FILE__), '../lib/cloudware')
Bundler.setup(:development)
require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.wait_timeout = 120

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
