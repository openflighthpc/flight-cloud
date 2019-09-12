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

require 'cloudware/models/deployment'

module Cloudware
  module Models
    class Node < Deployment
      def self.path(cluster, name)
        join_node_path(cluster, name, 'etc', 'config.yaml')
      end
      define_input_methods_from_path_parameters

      def self.join_node_path(cluster, name, *rest)
        RootDir.content_cluster(cluster.to_s, 'var/nodes', name, *rest)
      end

      def template_path
        ext = links.cluster.template_ext
        self.class.join_node_path(cluster, name, 'var', 'template' + ext)
      end

      data_reader(:primary_group) do |group|
        group || begin
          Models::Group.create_or_update(cluster, 'orphan').name
        end
      end

      data_writer(:primary_group) do |group|
        unless Models::Group.exists?(cluster, group)
          raise ModelValidationError, <<~ERROR
            Can not add node to primary group '#{group}' as it does not exist
          ERROR
        end
        group
      end

      def read_primary_group
        Models::Group.read(cluster, primary_group)
      end

      def read_groups
        Indices::GroupNode.glob_read(cluster, '*', name, '*')
                          .map(&:read_group)
      end

      def machine_client
        id = (results || {})[:"#{name}TAGID"]
        provider_client.machine(id)
      end
    end

    # Define the indices after the index model is loaded
    require 'cloudware/indices/group_node'
    class Node
      include FlightConfig::HasIndices

      has_indices(Indices::GroupNode) do |create|
        create.call(cluster, primary_group, name, :primary)
      end
    end
  end
end

