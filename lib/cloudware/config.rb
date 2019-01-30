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
require 'flight_config/loader'

require 'active_support/core_ext/module/delegation'

module Cloudware
  class Config
    class << self
      def cache
        @cache ||= new
      end

      def root_dir
        File.expand_path(File.join(__dir__, '..', '..'))
      end

      delegate_missing_to :cache
    end

    def initialize
      @__data__ = TTY::Config.new
      __data__.prepend_path(File.join(self.class.root_dir, 'etc'))
      __data__.env_prefix = 'cloudware'
      ['provider', 'debug', 'app_name'].each { |x| __data__.set_from_env(x) }
      load_config
    end

    def log_file
      __data__.fetch(:log_file) do
        File.join(self.class.root_dir, 'log', 'cloudware.log').tap do |path|
          FileUtils.mkdir_p(File.dirname(path))
        end
      end
    end

    def provider
      __data__.fetch(:provider) do
        warn 'No provider specified'
        exit 1
      end
    end

    [:azure, :aws].each do |init_provider|
      define_method(init_provider) do
        OpenStruct.new(__data__.fetch(init_provider))
      end
    end

    def default_region
      __data__.fetch(provider, :default_region)
    end

    def content_path
      __data__.fetch(:content_directory) do
        File.join(self.class.root_dir, 'var')
      end
    end

    def debug
      !!__data__.fetch(:debug)
    end

    def app_name
      __data__.fetch(:app_name) { File.basename($PROGRAM_NAME) }
    end

    private

    attr_reader :__data__

    def load_config
      __data__.read
    rescue TTY::Config::ReadError
      missing_config_error
    rescue
      invalid_config_error
    end

    def missing_config_error
      warn <<~ERROR.chomp
        Could not load the config file. Please check that it exists:
        <install-dir>/etc/config.yaml
      ERROR
      exit 1
    end

    def invalid_config_error
      warn <<~ERROR.chomp
        An error occurred when loading the config file:
        #{__data__.source_file}
      ERROR
      exit 1
    end
  end
end
