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
require 'flight_manifest'

require 'cloudware/models/domain'
require 'cloudware/models/node'

# TODO: Move me into the `flight_manifest` repo
# ALERT: See the following bug if the primary group causes and issue
# https://github.com/openflighthpc/flight_manifest/issues/1
module FlightManifest
  class Node
    def groups
      start = (primary_group ? [primary_group] : [])
      [*start, *secondary_groups]
    end
  end
end

module Cloudware
  module Commands
    class Import < Command
      def run!(path)
        abs_path = File.expand_path(path, Dir.pwd)
        manifest = FlightManifest.load(abs_path)
        template = manifest.domain[provider_file].expand_path(manifest.base)
        Models::Domain.create!(__config__.current_cluster) do |domain|
          domain.save_template(template)
        end
        manifest.nodes.each do |man|
          Models::Node.create!(__config__.current_cluster, man.name) do |node|
            node.save_template(man[provider_file].expand_path(manifest.base))
            node.groups = man.groups
          end
        end
      end

      private

      def registry
        @registry ||= FlightConfig::Registry.new
      end

      def cluster
        registry.read(Models::Profile, __config__.current_cluster)
      end

      def provider_file
        :"#{cluster.provider}_file"
      end
    end
  end
end
