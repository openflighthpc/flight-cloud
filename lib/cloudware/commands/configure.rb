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

require 'tty-prompt'

module Cloudware
  module Commands
    class Configure < Command
      def run
        file_data = IO.readlines(Config.path)
        access_details = Config.provider_details

        # Grab the line number in the config corresponding to the current
        # provider
        line_number = nil
        file_data.each_with_index do |line, index|
          if line.include?("#{Config.provider}:")
            line_number = index + 1
          end
        end

        prompt = TTY::Prompt.new
        puts "Provide access details for #{Config.provider}:"
        access_details.each_with_index do |(k, v), i|
          # Given the line number found before we know where in the config
          # file the access details are expected
          new_v = prompt.ask(k, default: v)
          file_data[line_number + i] = file_data[line_number + i].sub(v, new_v)
        end

        # Write the changes to the config file
        IO.write(Config.path, file_data.join)
      end
    end
  end
end
