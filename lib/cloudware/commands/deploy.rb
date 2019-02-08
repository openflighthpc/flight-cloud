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
        cluster = __config__.current_cluster
        path = resolve_template(raw_path)
        deployment = Models::Deployment.create(cluster, name) do |d|
          puts "Deploying: #{path}"
          with_spinner('Deploying resources...', done: 'Done') do
            d.template_path = path
            d.replacements = ReplacementFactory.new(context, name)
                                               .build(params)
            d.deploy
          end
        end
        return unless deployment.deployment_error
        raise DeploymentError, <<~ERROR.chomp
           An error has occured. Please see for further details:
          `#{Config.app_name} list deployments --verbose`
        ERROR
      rescue FlightConfig::CreateError => e
        new_e = e.exception <<~ERROR.chomp
          Cowardly refusing to re-deploy '#{name}'
        ERROR
        new_e.set_backtrace(e.backtrace)
        raise new_e
      end

      def list_templates(verbose: false)
        list = build_template_list
        if list.templates.empty?
          $stderr.puts 'No templates found'
        elsif verbose
          list.human_paths.each do |human_path, abs_path|
            puts "#{human_path} => #{abs_path}"
          end
        else
          list.shorthand_paths.each do |human_path, _|
            puts human_path
          end
        end
      end

      private

      attr_reader :name, :raw_path

      def resolve_template(template)
        build_template_list.human_paths[template] || ''
      end

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
          templates.each_with_object({}) do |template, memo|
            long_name = template.sub_ext('')
            name = long_name.basename
            directory = long_name.dirname
            directory_file = directory.sub_ext(template.extname)

            # Adds the shorthand path (if available)
            # The directory must not have a sibling template of the same name
            if (name == directory.basename) && !directory_file.file?
              memo[directory.relative_path_from(base).to_s] = template
            end

            # Adds the standard path
            memo[long_name.relative_path_from(base).to_s] = template
          end
        end

        def shorthand_paths
          human_paths.each_with_object({}) do |(name, path), memo|
            if memo.key?(path)
              memo[path] = name if memo[path].length > name.length
            else
              memo[path] = name
            end
          end.map { |v, k| [k, v] }.to_h
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
