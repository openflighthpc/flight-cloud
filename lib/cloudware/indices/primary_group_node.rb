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

require 'cloudware/index'
require 'cloudware/root_dir'

require 'cloudware/models/node'
require 'cloudware/models/group'

module Cloudware
  module Indices
    class PrimaryGroupNode < Cloudware::Index
      def self.path(cluster, group, node)
        CacheDir.join('cluster', cluster, 'primary_groups', group, 'nodes', node + '.index')
      end

      [:cluster, :group, :node].each_with_index do |method, idx|
        define_method(method) { __inputs__[idx] }
      end

      def read_node
        Models::Node.read(cluster, node, registry: __registry__)
      end

      def read_group
        Models::Group.read(cluster, node, registry: __registry__)
      end

      def valid?
        read_node.primary_group.name == read_group.name
      end
    end
  end
end

