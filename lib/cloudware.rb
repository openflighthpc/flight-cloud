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
require 'cloudware/cli'
require 'cloudware/domain'
require 'cloudware/machine'
require 'cloudware/azure'
require 'cloudware/gcp'
require 'cloudware/aws'
require 'cloudware/config'
require 'logger'

module Cloudware
  class << self
    def config
      @config ||= Config.new(ENV['CLOUDWARE_CONFIG'] || '/opt/cloudware/etc/config.yml')
    end

    def log
      @log ||= Logger.new(config.log_file)
    end

    def render_file_path(path)
      File.expand_path(File.join(__dir__, "../providers/#{path}"))
    end
  end
end
