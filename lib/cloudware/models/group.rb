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

require 'cloudware/models/cluster'
require 'cloudware/models/node'

module Cloudware
  module Models
    class Group < Deployment
      allow_missing_read

      def self.join(cluster, name, *rest)
        RootDir.content_cluster(cluster, 'var/groups', name, *rest)
      end

      def self.path(cluster, name)
        join(cluster, name, 'etc/config.yaml')
      end
      define_input_methods_from_path_parameters

      def join(*rest)
        self.class.join(*__inputs__, *rest)
      end

      def read_cluster
        Models::Cluster.read(cluster, registry: __registry__)
      end

      data_reader(:other_nodes) { |n| n || [] }
      data_writer(:other_nodes) do |nodes|
        if nodes.nil? || nodes.is_a?(Array)
          nodes
        else
          [nodes]
        end
      end

      def read_other_nodes
        other_nodes.map do |node|
          Models::Node.read(cluster, node, registry: __registry__)
        end
      end

      def read_primary_nodes
        Index::GroupNode.glob_read(cluster, name, '*', :primary)
                        .map(&:read_node)
      end

      def read_nodes
        Index::GroupNode.glob_read(cluster, name, '*', '*')
                        .map(&:read_node)
      end

      def template_path
        join('var', 'template' + read_cluster.template_ext)
      end
    end

    require 'cloudware/indices/group_node'
    class Group
      include FlightConfig::HasIndices


      has_indices(Indices::GroupNode) do |create|
        other_nodes.each do |node|
          create.call(cluster, name, node, :other)
        end
      end
    end
  end
end

