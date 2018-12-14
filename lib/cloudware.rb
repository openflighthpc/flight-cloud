# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================

lib_dir = File.dirname(__FILE__)
$LOAD_PATH << File.join(lib_dir, 'cloudware')
ENV['BUNDLE_GEMFILE'] ||= File.join(lib_dir, '..', 'Gemfile')

Thread.report_on_exception = false

require 'rubygems'
require 'bundler'
Bundler.setup(:default)

# ActiveSupport modules
require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 'active_model'
require 'active_model/errors'

require 'colorize'
require 'config'
require 'logger'
require 'memoist'
require 'parallel'

require 'data'

module Cloudware
  class << self
    def config
      @config ||= Config.new
    end

    def log
      @log ||= Logger.new(config.log_file)
    end

    def root_dir
      @root_dir ||= File.dirname(__FILE__)
    end
  end
end

require 'cli'
