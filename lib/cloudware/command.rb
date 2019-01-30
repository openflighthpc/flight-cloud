# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Flight Ltd
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

require 'cloudware/spinner'
require 'cloudware/log'
require 'cloudware/command_config'

module Cloudware
  class Command
    extend Memoist
    include WithSpinner

    attr_reader :__config__

    def initialize(__config__ = nil)
      @__config__ = __config__ || CommandConfig.load
    end

    def run!(*argv, **options)
      class << self
        attr_reader :argv, :options
      end
      @argv = argv.freeze
      @options = OpenStruct.new(options)
      run
    end

    def run
      raise NotImplementedError
    end

    def context
      Context.new(region: __config__.region)
    end
    memoize :context

    def region
      __config.__.region
    end
  end
end
