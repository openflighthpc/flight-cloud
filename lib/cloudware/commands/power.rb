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

module Cloudware
  module Commands
    class Power < Command
      attr_reader :identifier

      def status_cli(*a)
        set_arguments(*a)
        machines.each  { |m| puts "#{m.name}: #{m.status}"}
      end

      def on_cli(*a)
        set_arguments(*a)
        machines.each do |machine|
          puts "Turning on: #{machine.name}"
          machine.on
        end
      end

      def off_cli(*a)
        set_arguments(*a)
        machines.each do |machine|
          puts "Turning off: #{machine.name}"
          machine.off
        end
      end

      private

      attr_reader :identifier, :group

      def set_arguments(identifier, group: false)
        @identifier = identifier
        @group = group
      end

      def machines
        if group
          Models::Deployments.read(__config__.current_cluster)
                             .machines
                             .select { |m| m.groups.include?(identifier) }
        else
          [Models::Machine.new(name: identifier, cluster: __config__.current_cluster)]
        end
      end
    end
  end
end
