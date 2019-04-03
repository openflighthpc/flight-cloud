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
        SECTION = /(domain|(group|node)\/[^\/]*)/
        TEMPLATE_REMOVE = /#{Config.provider}\/#{SECTION}\/platform/
        TEMPLATE_REPLACE = /(?<=#{Config.provider}\/)#{SECTION}/
        TEMPLATE_GLOB = "#{Config.provider}/{domain,{group,node}/*}/platform/**/*#{Config.template_ext}"

        delegate_missing_to :zip_file

        def self.extract(path)
          Zip::File.open(path) do |f|
            yield new(f) if block_given?
          end
        end

        ##
        # Strip the root provider directory and the `platform`
        # sub directory from the destination path
        #
        def self.dst_template_path(src, base)
          replace = src.match(TEMPLATE_REPLACE)[0]
          Pathname.new(src)
                  .sub(/#{TEMPLATE_REMOVE}/, replace)
                  .expand_path(base)
        end

        def copy_templates(cluster)
          base = RootDir.content_cluster_template(cluster)
          templates.each do |zip_src|
            dst = self.class.dst_template_path(zip_src.name, base)
            dst.dirname.mkpath
            if dst.exist?
              $stderr.puts "Skipping, file already exists: #{dst}"
            else
              zip_src.extract(dst)
              puts "Imported: #{dst}"
            end
          end
        end

        def templates
          glob(TEMPLATE_GLOB).reject(&:directory?)
        end
      end
    end
  end
end
