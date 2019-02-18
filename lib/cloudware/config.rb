# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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

      delegate_missing_to :cache
    end

    def initialize
      __data__.env_prefix = 'cloudware'
      ['provider', 'debug', 'app_name'].each { |x| __data__.set_from_env(x) }
    end

    def path
      File.join(root_dir, 'etc/config.yaml')
    end

    def root_dir
      File.expand_path(File.join(__dir__, '..', '..'))
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

    def prefix_tag
      __data__.fetch(:prefix_tag, default: 'cloudware-shared')
    end
    alias :append_tag :prefix_tag

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
