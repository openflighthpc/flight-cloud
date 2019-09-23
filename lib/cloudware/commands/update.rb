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

require 'cloudware/replacement_factory'

module Cloudware
  module Commands
    class Update < ScopedCommand
      def run(*params)
        params_string = params.join(' ')
        dep_name = (model_klass == Models::Domain ? 'domain' : name_or_error)
        replacements = ReplacementFactory.new(config.current_cluster, dep_name)
                                         .build(params_string)
        model_klass.prompt!(replacements, *read_model.__inputs__)
      end

      def node(primary_group: nil, other_groups: nil)
        require 'cloudware/models/group'
        require 'cloudware/models/node'
        if primary_group
          Models::Node.update(*read_node.__inputs__) do |node|
            node.primary_group = primary_group
          end
        end
        if other_groups
          other_groups.split(',').each do |group_name|
            Models::Group.create_or_update(cluster_name, group_name) do |group|
              group.other_nodes = group.other_nodes.dup.tap { |n| n << name_or_error }
            end
          end
        end
      end
    end
  end
end
