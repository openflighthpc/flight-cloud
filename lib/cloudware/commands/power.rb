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

require 'cloudware/models/group'

module Cloudware
  module Commands
    class Power < Command
      attr_reader :identifier, :instance_type

      def status_cli(*a)
        set_arguments(*a)
        machines.each  { |m| puts "#{m.name}: #{m.status rescue 'undeployed'}"}
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

      def status_hash(*a)
        set_arguments(*a)
        hashify_machines { |m| m.status }
      end

      def on_hash(*a)
        set_arguments(*a)
        hashify_machines { |m| m.on }
      end

      def off_hash(*a)
        set_arguments(*a)
        hashify_machines { |m| m.off }
      end

      private

      attr_reader :identifier, :group

      def set_arguments(identifier, group: false, instance: nil)
        @identifier = identifier
        @group = group
        @instance_type = instance
      end

      def hashify_machines
        machines.each_with_object({ nodes: {}, errors: {} }) do |machine, memo|
          begin
            memo[:nodes][machine.name] = yield machine
          rescue CloudwareError => e
            memo[:errors][machine.name] = e.message
          rescue FlightConfig::MissingFile
            memo[:errors][machine.name] = 'The node does not exist'
          rescue NoMethodError
            memo[:nodes][machine.name] = 'undeployed'
          end
        end
      end

      def machines
        if group
          Models::Group.read(__config__.current_cluster, identifier).nodes.sort_by { |n| n.name }
            .map do |node|
            Models::Machine.new(name: node.name, cluster: __config__.current_cluster)
          end
        else
          [Models::Machine.new(name: identifier, cluster: __config__.current_cluster)]
        end
      end
    end
  end
end
