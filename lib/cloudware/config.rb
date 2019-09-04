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
    include FlightConfig::Updater
    allow_missing_read

    class << self
      def cache
        @cache ||= self.load
      end

      def root_dir
        File.expand_path(File.join(__dir__, '..', '..'))
      end

      def path(*_)
        File.join(root_dir, 'etc', 'config.yaml')
      end

      delegate_missing_to :cache
    end

    def __data__
      super.tap do |__data__|
        __data__.env_prefix = 'cloudware'
        ['debug', 'app_name', 'server_mode'].each do |x|
          __data__.set_from_env(x)
        end
      end
    end

    def root_dir
      self.class.root_dir
    end

    def log_file
      dir = __data__.fetch(:log_directory) do
        File.join(self.class.root_dir, 'log').tap { |d| FileUtils.mkdir_p(d) }
      end
      File.join(dir, 'cloud.log')
    end

    def prefix_tag
      __data__.fetch(:prefix_tag, default: 'cloudware-shared')
    end

    [:azure, :aws].each do |init_provider|
      define_method(init_provider) do |allow_missing: false|
        provider_data = __data__.fetch(init_provider) do
          next {} if allow_missing
          raise ConfigError, <<~ERROR.chomp
            The config is missing the credentials for: #{init_provider}
            Please see the example config file for details:
            #{path}.example
          ERROR
        end
        OpenStruct.new(provider_data)
      end

      define_method("#{init_provider}=") do |value|
        __data__.set(init_provider, value: value.to_h)
      end
    end

    def default_regions
      {
        aws: __data__.fetch(:aws, :default_region),
        azure: __data__.fetch(:azure, :default_region)
      }
    end

    def content(*paths)
      File.join(content_path, *paths)
    end

    def content_path
      __data__.fetch(:content_directory) do
        File.join(self.class.root_dir, 'var')
      end
    end

    def server_cluster
      __data__.fetch(:server_cluster) { 'server' }
    end

    def debug
      !!__data__.fetch(:debug)
    end

    def app_name
      __data__.fetch(:app_name) { File.basename($PROGRAM_NAME) }
    end

    def server_mode
      __data__.fetch(:server_mode) { false }
    end

    def ssl_certificate?
      File.exists? ssl_certificate_path
    end

    def ssl_private_key?
      File.exists? ssl_private_key_path
    end

    def jwt_shared_secret
      __data__.fetch(:jwt_shared_secret) do
        raise ConfigError, 'The jwt_shared_secret has not been set in the config'
      end
    end

    def read_ssl_certificate
      if ssl_certificate?
        File.read ssl_certificate_path
      else
        raise ConfigError, "Can not locate ssl certificate: #{ssl_certificate_path}"
      end
    end

    def read_ssl_private_key
      if ssl_private_key?
        File.read ssl_private_key_path
      else
        raise ConfigError, "Can not locate ssl private: #{ssl_private_key_path}"
      end
    end

    def ssl_certificate_path
      __data__.fetch(:ssl_certificate) do
        File.join(self.class.root_dir, 'etc', 'ssl.crt')
      end
    end

    def ssl_private_key_path
      __data__.fetch(:ssl_private_key) do
        File.join(self.class.root_dir, 'etc', 'ssl.key')
      end
    end
  end
end
