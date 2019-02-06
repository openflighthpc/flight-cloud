# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Flight Ltd
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

require 'cloudware/cluster'
require 'pathname'

module Cloudware
  module Commands
    class ClusterCommand < Command
      LIST_CLUSTERS = <<~ERB
        <% clusters = load_clusters -%>
        <% unless clusters.include?(__config__.current_cluster) -%>
        * <%= __config__.current_cluster %>
        <% end -%>
        <% clusters.each do |cluster| -%>
        <%   current = __config__.current_cluster == cluster -%>
        <%=  current ? '*' : ' ' %> <%= cluster %>
        <% end -%>
      ERB

      def init(cluster)
        error_if_exists(cluster, action: 'create')
        FileUtils.mkdir_p Cluster.load(cluster).path
        update_cluster(cluster)
        list
      end

      def list
        puts _render(LIST_CLUSTERS)
      end

      def switch(cluster)
        error_if_missing(cluster, action: 'switch')
        update_cluster(cluster)
        list
      end

      private

      def update_cluster(new_cluster)
        @__config__ = CommandConfig.update do |conf|
          conf.current_cluster = new_cluster
        end
      end

      def load_clusters
        Dir.glob(Cluster.new('*').join)
           .map { |p| File.basename(p) }
           .sort
      end

      def error_if_exists(cluster, action:)
        return unless load_clusters.include?(cluster)
        raise InvalidInput, <<~ERROR.chomp
          Failed to #{action} cluster. '#{cluster}' already exists
        ERROR
      end

      def error_if_missing(cluster, action:)
        return if load_clusters.include?(cluster)
        raise InvalidInput, <<~ERROR.chomp
          Failed to #{action} cluster. '#{cluster}' doesn't exist
        ERROR
      end
    end
  end
end
