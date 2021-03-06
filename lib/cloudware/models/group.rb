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

require 'cloudware/models/cluster'
require 'cloudware/models/node'

module Cloudware
  module Models
    class Group
      include FlightConfig::Reader
      include FlightConfig::Accessor
      include FlightConfig::Links

      allow_missing_read

      def self.path(cluster, name)
        RootDir.content_cluster(cluster, 'var/groups', name, 'etc/config.yaml')
      end
      define_input_methods_from_path_parameters

      def nodes
        Models::Node.glob_read(cluster, '*', registry: __registry__)
                    .select { |n| n.groups.include?(name) }
      end
    end
  end
end

