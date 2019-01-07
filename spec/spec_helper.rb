# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)
require File.join(File.dirname(__FILE__), '../lib/cloudware')

require 'rspec/wait'

require 'pry'
require 'pry-byebug'
require 'fakefs/spec_helpers'
require 'factory_bot'

SPEC_DIR = __dir__
ENV['CLOUDWARE_PROVIDER'] = 'aws'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers::All
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # Clones in the default config file into the faked file system
  config.before do
    src = File.join(SPEC_DIR, 'fixtures/default-config.yaml')
    FileUtils.mkdir_p(File.dirname(Cloudware::Config::PATH))
    FakeFS::FileSystem.clone(src, Cloudware::Config::PATH)
    allow_any_instance_of(File).to receive(:flock)
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
