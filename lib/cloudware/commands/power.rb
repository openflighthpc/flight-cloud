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
    class ScopedPower < ScopedCommand
      def status_cli
        read_nodes.each { |n| puts "#{n.name}: #{n.machine_client.status rescue 'undeployed'}"}
      end

      def off_cli
        read_nodes.each do |node|
          puts "Turning off: #{node.name}"
          node.machine_client.off
        end
      end

      # TODO: Add resize_instance back
      def on_cli
        read_nodes.each do |node|
          # resize_instance(node) unless instance_type.nil?
          puts "Turning on: #{node.name}"
          node.machine_client.on
        end
      end

      private

      def resize_instance(node)
        unless node.machine_client.status == 'stopped'
          raise RuntimeError, <<~ERROR.chomp
            The instance must be stopped to resize it
          ERROR
        end

        puts "Resizing #{node.name} to #{instance_type}"
        node.machine_client.modify_instance_type(instance_type)
      end
    end

    class Power < Command
      def status_hash(*a)
        set_arguments(*a)
        hashify_nodes { |m| m.machine_client.status }
      end

      def on_hash(*a)
        set_arguments(*a)
        hashify_nodes do |m|
          resize_instance(m) unless instance_type.nil?
          m.machine_client.on
        end
      end

      def off_hash(*a)
        set_arguments(*a)
        hashify_nodes { |m| m.machine_client.off }
      end

      private

      attr_reader :identifier, :group, :instance_type

      def set_arguments(identifier, group: false, instance: nil)
        @identifier = identifier
        @group = group
        @instance_type = instance
      end

      def hashify_nodes
        nodes.each_with_object({ nodes: {}, errors: {} }) do |node, memo|
          begin
            memo[:nodes][node.name] = yield node
          rescue CloudwareError => e
            memo[:errors][node.name] = e.message
          rescue FlightConfig::MissingFile
            memo[:errors][node.name] = 'The node does not exist'
          rescue NoMethodError
            memo[:nodes][node.name] = 'undeployed'
          end
        end
      end

      def nodes
        if group
          Models::Group.read(__config__.current_cluster, identifier).nodes.sort_by { |n| n.name }
        else
          [Models::Node.read(__config__.current_cluster, identifier)]
        end
      end

      def resize_instance(node)
        unless node.machine_client.status == 'stopped'
          raise RuntimeError, <<~ERROR.chomp
            The instance must be stopped to resize it
          ERROR
        end

        puts "Resizing #{node.name} to #{instance_type}"
        node.machine_client.modify_instance_type(instance_type)
      end
    end
  end
end
