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

require 'ostruct'
require 'tty-config'

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
      @config = TTY::Config.new
      config.prepend_path(File.join(self.class.root_dir, 'etc'))
      config.env_prefix = 'cloudware'
      config.set_from_env('provider')
      config.read
    end

    def log_file
      config.fetch(:general, :log_file)
    end

    def provider
      config.fetch(:provider)
    end

    [:azure, :aws].each do |init_provider|
      define_method(init_provider) do
        OpenStruct.new(config.fetch(init_provider))
      end
    end

    def default_region
      config.fetch(provider, :default_region)
    end

    def content_path
      File.join(self.class.root_dir, 'var')
    end

    private

    attr_reader :config
  end
end
