# frozen_string_literal: true

require 'rspec/wait'
require File.join(File.dirname(__FILE__), '../lib/cloudware')
Bundler.setup(:development)
require 'pry'
require 'pry-byebug'
require 'fakefs/spec_helpers'
require 'factory_bot'

SPEC_DIR = File.expand_path(File.dirname(__FILE__))
ENV['CLOUDWARE_PROVIDER'] = 'aws'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers::All
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # Clones in the default config file into the faked file system
  config.before(:each) do
    src = File.join(SPEC_DIR, 'fixtures/default-config.yaml')
    FileUtils.mkdir_p(File.dirname(Cloudware::Config::PATH))
    FakeFS::FileSystem.clone(src, Cloudware::Config::PATH)
  end

  config.after { FakeFS.clear! }

  config.wait_timeout = 120

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
