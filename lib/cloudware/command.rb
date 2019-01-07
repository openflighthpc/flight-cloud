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

require 'cloudware/spinner'
require 'cloudware/log'

module Cloudware
  class Command
    extend Memoist
    include WithSpinner

    def initialize(argv, options)
      @argv = argv.freeze
      @options = OpenStruct.new(options.__hash__)
    end

    def run!
      run
    rescue Exception => e
      Log.fatal(e.message)
      raise e
    end

    def run
      raise NotImplementedError
    end

    def context
      Context.new(region: options.region)
    end
    memoize :context

    def region
      options.region || Config.default_region
    end

    private

    attr_reader :argv, :options
  end
end
