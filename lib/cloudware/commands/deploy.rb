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

module Cloudware
  module Commands
    class Deploy < Command
      def self.delayed_require
        super
        require 'cloudware/replacement_factory'
      end

      def run!(name, raw_path = nil, params: nil)
        cur_dep = if raw_path
          create_deployment(name, raw_path, params: params)
        else
          Models::Deployment.read(__config__.current_cluster, name)
        end
        raise_if_deployed(cur_dep)
        puts "Deploying: #{cur_dep.path}"
        with_spinner('Deploying resources...', done: 'Done') do
          dep = Models::Deployment.deploy!(__config__.current_cluster, name)
          return unless dep.deployment_error
          raise DeploymentError, <<~ERROR.chomp
             An error has occured. Please see for further details:
            `#{Config.app_name} list deployments --verbose`
          ERROR
        end
      end

      def render(name, template = nil, params: nil)
        cluster = __config__.current_cluster
        deployment = Models::Deployment.read_or_new(cluster, name)
        unless deployment.template_path
          path = resolve_template(template, error_missing: true)
          deployment.template_path = path
          deployment.replacements = ReplacementFactory.new(cluster, name)
                                                      .build(params)
        end
        puts deployment.template
      end

      def list_templates(verbose: false)
        list = build_template_list
        if list.templates.empty?
          raise UserError, 'No templates found'
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

      def create_deployment(name, raw_path, params: nil)
        replacements = ReplacementFactory.new(__config__.current_cluster, name)
                                         .build(params)
        Models::Deployment.create!(
          __config__.current_cluster, name,
          template: resolve_template(raw_path),
          replacements: replacements
        )
      end

      def raise_if_deployed(dep)
        return unless dep.deployed
        raise InvalidInput, "'#{dep.name}' is already running"
        ERROR
      end

      def resolve_template(template, error_missing: false)
        path = build_template_list.human_paths[template]
        return path if path
        return '' unless error_missing
        raise InvalidInput, 'Could not resolve template path'
      end

      def build_template_list
        ListTemplates.new(__config__.current_cluster)
      end

      ListTemplates = Struct.new(:cluster) do
        include Enumerable

        delegate :each, to: :templates

        def template_path(*parts, ext: true)
          path = RootDir.content_cluster_template(cluster, *parts)
          path = Pathname.new(path)
          ext ? path.sub_ext(Config.template_ext) : path
        end

        def base
          template_path(ext: false)
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
          @templates ||= Dir.glob(template_path('**/*'))
                            .sort
                            .map { |p| Pathname.new(p) }
        end
      end
    end
  end
end
