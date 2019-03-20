# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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
  end
end

