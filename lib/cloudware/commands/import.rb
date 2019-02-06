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

require 'pathname'
require 'zip'

module Cloudware
  module Commands
    class Import < Command
      def run!(raw_path)
        zip_path = Pathname.new(raw_path).expand_path.sub_ext('.zip').to_s
        ZipImporter.extract(zip_path) do |zip|
          zip.copy_templates(__config__.current_cluster)
        end
      end

      private

      ZipImporter = Struct.new(:zip_file) do
        delegate_missing_to :zip_file

        def self.extract(path)
          Zip::File.open(path) do |f|
            yield new(f) if block_given?
          end
        end

        def self.dst_template_path(src, base)
          Pathname.new(src)
                  .sub(/\Aaws\//, '')
                  .expand_path(base)
        end

        def copy_templates(cluster)
          base = Cluster.load(cluster).template(ext: false)
          templates.each do |zip_src|
            dst = self.class.dst_template_path(zip_src.name, base)
            dst.dirname.mkpath
            if dst.exist?
              $stderr.puts "Skipping, file already exists: #{dst}"
            else
              extract(dst)
              puts "Imported: #{dst}"
            end
          end
        end

        def templates
          glob_path = 'aws/{domain,{group,node}/*}/platform/templates/**/*'
          glob(glob_path).reject(&:directory?)
        end
      end
    end
  end
end
