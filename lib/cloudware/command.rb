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

require 'cloudware/spinner'
require 'cloudware/log'
require 'cloudware/command_config'
require 'memoist'

module Cloudware
  class Command
    extend Memoist
    include WithSpinner

    # Override this method to delay requiring libraries until the command is
    # called. Remember to `super`
    def self.delayed_require
      require 'cloudware/models'
    end

    attr_reader :__config__

    def initialize(__config__ = nil)
      self.class.delayed_require
      @__config__ = __config__ || CommandConfig.read
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

    def region
      __config__.region
    end

    private

    def _render(template)
      ERB.new(template, nil, '-').result(binding)
    end
  end
end
