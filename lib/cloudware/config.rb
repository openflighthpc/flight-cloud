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

require 'ostruct'
require 'flight_config'
require 'active_support/core_ext/module/delegation'

require 'cloudware/exceptions'

module Cloudware
  class Config
    include FlightConfig::Loader
    allow_missing_read

    class << self
      def cache
        @cache ||= self.load
      end

      def root_dir
        File.expand_path(File.join(__dir__, '..', '..'))
      end

      def path(_)
        File.join(root_dir, 'etc/config.yaml')
      end

      delegate_missing_to :cache
    end

    def __data__
      super.tap do |__data__|
        __data__.env_prefix = 'cloudware'
        ['provider', 'debug', 'app_name'].each { |x| __data__.set_from_env(x) }
      end
    end

    def root_dir
      self.class.root_dir
    end

    def log_file
      dir = __data__.fetch(:log_directory) do
        File.join(self.class.root_dir, 'log').tap { |d| FileUtils.mkdir_p(d) }
      end
      File.join(dir, provider + '.log')
    end

    def provider
      __data__.fetch(:provider) do
        raise ConfigError, 'No provider specified'
      end
    end

    def provider_details
      Data.load(path)[provider.to_sym]
    end

    def prefix_tag
      __data__.fetch(:prefix_tag, default: 'cloudware-shared')
    end

    def template_ext
      provider == 'azure' ? '.json' : '.yaml'
    end

    [:azure, :aws].each do |init_provider|
      define_method(init_provider) do
        provider_data = __data__.fetch(init_provider) do
          raise ConfigError, <<~ERROR.chomp
            The config is missing the credentials for: #{init_provider}
            Please see the example config file for details:
            #{path}.example
          ERROR
        end
        OpenStruct.new(provider_data)
      end
    end

    def default_region
      __data__.fetch(provider, :default_region) do
        raise ConfigError, <<~ERROR.chomp
          The 'default_region' has not been set in the config
          Please see the example config file for details:
          #{path}.example
        ERROR
      end
    end

    def content(*paths)
      File.join(content_path, *paths)
    end

    def content_path
      base = __data__.fetch(:content_directory) do
        File.join(self.class.root_dir, 'var')
      end
      File.join(base, provider)
    end

    def debug
      !!__data__.fetch(:debug)
    end

    def app_name
      __data__.fetch(:app_name) { File.basename($PROGRAM_NAME) }
    end
  end
end
