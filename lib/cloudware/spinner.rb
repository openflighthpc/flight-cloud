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

require 'tty-spinner'

module Cloudware
  class Spinner
    def initialize(message, **k)
      @tty_spinner = TTY::Spinner.new(message, **k)
    end

    def run(done_message = '')
      tty_spinner.spin      # Always spin once
      tty_spinner.auto_spin unless Config.debug
      yield if block_given?
    ensure
      tty_spinner.stop(done_message)
    end

    private

    attr_reader :tty_spinner
  end

  module WithSpinner
    def with_spinner(msg = '', done: '', &block)
      Spinner.new("[:spinner] #{msg}", format: :pipe)
             .run(done, &block)
    end
  end
end
