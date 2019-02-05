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
        cluster = Cluster.load(__config__.current_cluster)
        Zip::File.open(zip_path) do |zip|
          zip.glob('aws/**/*').reject(&:directory?).each do |file|
            dst = Pathname.new(file.name)
                          .sub(/\Aaws\//, '')
                          .expand_path(cluster.template(ext: false))
                          .tap { |p| p.dirname.mkpath }
            if dst.exist?
              $stderr.puts "Skipping, file already exists: #{dst}"
            else
              file.extract(dst)
              puts "Imported: #{dst}"
            end
          end
        end
      end
    end
  end
end
