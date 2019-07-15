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
        ZipImporter.extract(zip_path, __config__.current_cluster)
      end

      private

      ZipImporter = Struct.new(:zip_file, :cluster) do
        SECTION = /(domain|(group|node)\/[^\/]*)/

        delegate :provider, :template_ext, to: :cluster_model
        delegate_missing_to :zip_file

        def self.extract(path, cluster)
          Zip::File.open(path) do |f|
            new(f, cluster).copy_templates
          end
        end

        def copy_templates
          base = RootDir.content_cluster_template(cluster)
          templates.each do |zip_src|
            dst = dst_template_path(zip_src.name, base)
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
          glob(template_glob).reject(&:directory?)
        end

        private

        def cluster_model
          @cluter_model ||= Models::Cluster.read(cluster)
        end

        def template_remove
          /#{provider}\/#{SECTION}\/platform/
        end

        def template_replace
          /(?<=#{provider}\/)#{SECTION}/
        end

        def template_glob
          "#{provider}/{domain,{group,node}/*}/platform/**/*#{template_ext}"
        end

        ##
        # Strip the root provider directory and the `platform`
        # sub directory from the destination path
        #
        def dst_template_path(src, base)
          replace = src.match(template_replace)[0]
          Pathname.new(src)
                  .sub(/#{template_remove}/, replace)
                  .expand_path(base)
        end
      end
    end
  end
end
