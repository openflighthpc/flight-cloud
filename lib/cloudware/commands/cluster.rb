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
    class ClusterCmd < Command
      LIST_CLUSTERS = <<~ERB
        <% unless clusters.include?(__config__.current_cluster) -%>
        * <%= __config__.current_cluster %>
        <% end -%>
        <% clusters.each do |cluster| -%>
        <%   current = __config__.current_cluster == cluster -%>
        <%=  current ? '*' : ' ' %> <%= cluster %>
        <% end -%>
      ERB

      LIST_TEMPLATES = <<~ERB
      ERB

      def switch(cluster)
        @__config__ = CommandConfig.update do |conf|
          conf.current_cluster = cluster
        end
        list
      end

      def list
        puts _render(LIST_CLUSTERS)
      end

      def list_templates(verbose: false)
        list = ListTemplates.build(__config__.current_cluster)
        if list.templates.empty?
          $stderr.puts 'No templates found'
        else
          list.human_paths.each do |human_path, abs_path|
            print human_path
            print " => #{abs_path}" if verbose
            puts
          end
        end
      end

      private

      ListTemplates = Struct.new(:cluster) do
        include Enumerable

        delegate :each, to: :templates

        def self.build(cluster_name)
          new(Cluster.load(cluster_name))
        end

        def base
          cluster.template(ext: false)
        end

        ##
        # These represent the valid template CLI inputs
        #
        def human_paths
          templates.map do |template|
            name = template.basename.sub_ext('')
            dir_name = template.dirname.basename
            alternate = template.dirname.dirname.join(template.basename)

            # Detect shorthand enabled templates
            shorthand = (name == dir_name && !alternate.file?)
            relative = template.dirname.relative_path_from(base)

            human_path = shorthand ? relative : File.join(relative, name)
            [human_path, template]
          end.to_h
        end

        def templates
          @templates ||= Dir.glob(cluster.template('**/*'))
                            .sort
                            .map { |p| Pathname.new(p) }
        end
      end

      def clusters
        Dir.glob(Cluster.new('*').directory)
           .map { |p| File.basename(p) }
           .sort
      end
    end
  end
end
