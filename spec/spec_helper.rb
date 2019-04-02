# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

require 'rubygems'
require 'bundler'

Bundler.setup(:default, :config, :development)
ENV['CLOUDWARE_PROVIDER'] = 'aws'
require File.join(File.dirname(__FILE__), '../lib/cloudware')

require 'rspec/wait'

require 'pry'
require 'pry-byebug'
require 'fakefs/spec_helpers'
require 'factory_bot'

SPEC_DIR = __dir__

module FakeFS
  class Pathname
    def to_str
      self.to_s
    end

    delegate_missing_to :to_str
  end
end

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers::All
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before do
    # Moves the config into place
    src = File.join(SPEC_DIR, 'fixtures/default-config.yaml')
    dst = File.join(Cloudware::Config.root_dir, 'etc', 'config.yaml')
    FileUtils.mkdir_p(File.dirname(dst))
    FakeFS::FileSystem.clone(src, dst)

    FileUtils.mkdir_p(File.dirname(Cloudware::Config.log_file))

    # Stub the `flock` method in the tests as FakeFS doesn't implement it
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
