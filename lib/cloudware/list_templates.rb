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

module Cloudware
  ListTemplates = Struct.new(:cluster) do
    include Enumerable

    delegate :each, to: :templates

    def template_path(*parts, ext: true)
      path = RootDir.content_cluster_template(cluster, *parts)
      path = Pathname.new(path)
      if ext
        new_ext = registry.read(Models::Profile, cluster).template_ext
        path.sub_ext(new_ext)
      else
        path
      end
    end

    def base
      template_path(ext: false)
    end

    ##
    # Resolves CLI inputs to a absolute path
    #
    def resolve_human_path(relative)
      human_paths[relative]
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

    private

    def registry
      @registry ||= FlightConfig::Registry.new
    end
  end
end
