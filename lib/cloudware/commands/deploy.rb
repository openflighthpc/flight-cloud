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

require 'cloudware/cluster'

module Cloudware
  module Commands
    class Deploy < Command
      def initialize(*a)
        require 'cloudware/models/deployment'
        require 'cloudware/replacement_factory'
        super
      end

      def run!(name, raw_path, params: nil)
        path = build_template_list.human_paths[raw_path] || ''
        puts "Deploying: #{path}"
        with_spinner('Deploying resources...', done: 'Done') do
          Models::Deployment.new(
            template_path: path,
            name: name,
            cluster: __config__.current_cluster,
            replacements: ReplacementFactory.new(context, name)
                                            .build(params)
          ).deploy
        end
      end

      def list_templates(verbose: false)
        list = build_template_list
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

      attr_reader :name, :raw_path

      def build_template_list
        ListTemplates.build(__config__.current_cluster)
      end

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
            [human_path.to_s, template]
          end.to_h
        end

        def templates
          @templates ||= Dir.glob(cluster.template('**/*'))
                            .sort
                            .map { |p| Pathname.new(p) }
        end
      end
    end
  end
end
