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
  module Commands
    class Group < ScopedCommand
      def run_add_nodes(*names)
        primary ? add_primary_nodes(*names) : add_other_nodes(*names)
      end

      def add_primary_nodes(*names)
        load_existing_nodes(names).each do |node|
          Models::Node.update(*node.__inputs__) do |n|
            n.primary_group = name_or_error
          end
        end
      end

      def add_other_nodes(*raw_names)
        names = load_existing_nodes(raw_names).map(&:name)
        Models::Group.update(*read_group.__inputs__) do |group|
          group.other_nodes = [*group.other_nodes, *names].uniq
        end
      end
    end
  end
end

