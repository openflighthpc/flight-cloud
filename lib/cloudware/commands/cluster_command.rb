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
require 'cloudware/commands/import'
require 'pathname'

module Cloudware
  module Commands
    class ClusterCommand < Command
      LIST_CLUSTERS = <<~ERB
        <% clusters = read_clusters -%>
        <% unless clusters.include?(__config__.current_cluster) -%>
        * <%= __config__.current_cluster %>
        <% end -%>
        <% clusters.each do |cluster| -%>
        <%   current = __config__.current_cluster == cluster -%>
        <%=  current ? '*' : ' ' %> <%= cluster %>
        <% end -%>
      ERB

      def initialize(*_a)
        require 'parallel'
        super
      end

      def init(identifier, provider, import: nil)
        new_cluster = Models::Cluster.create!(identifier, provider: provider)
        update_cluster(new_cluster.identifier)
        Import.new(__config__).run!(import) if import
        puts "Created cluster: #{new_cluster.identifier}"
      end

      def list
        puts _render(LIST_CLUSTERS)
      end

      def switch(cluster)
        error_if_missing(cluster, action: 'switch')
        update_cluster(cluster)
        list
      end

      def delete(cluster)
        raise InvalidAction, 'Deleting a cluster is not currently supported :('
      end

      def show
        cluster = Models::Cluster.read(__config__.current_cluster)
        puts "Cluster: #{cluster.identifier}"
        puts "Nodes: #{cluster.read_nodes.map(&:name).join(',')}"
      end

      private

      def update_cluster(new_cluster)
        @__config__ = CommandConfig.create_or_update do |conf|
          conf.current_cluster = new_cluster
        end
      end

      def read_clusters
        Models::Cluster.glob_read('*').map { |c| c.identifier }
      end

      def error_if_exists(cluster, action:)
        return unless read_clusters.include?(cluster)
        raise InvalidInput, <<~ERROR.chomp
          Failed to #{action} cluster. '#{cluster}' already exists
        ERROR
      end

      def error_if_missing(cluster, action:)
        return if read_clusters.include?(cluster)
        raise InvalidInput, <<~ERROR.chomp
          Failed to #{action} cluster. '#{cluster}' doesn't exist
        ERROR
      end

      def error_if_current_cluster(cluster)
        return unless cluster == __config__.current_cluster
        raise InvalidInput, <<~ERROR.chomp
          Can not delete the current cluster
        ERROR
      end
    end
  end
end
