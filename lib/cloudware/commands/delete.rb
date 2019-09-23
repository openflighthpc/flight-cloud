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
    class Delete < ScopedCommand
      def deployable(force: false)
        model_klass.delete!(*read_model.__inputs__, force: force)
      end

      def group
        group = read_group
        if group.read_primary_nodes.empty? && group.read_other_nodes.empty?
          Models::Group.delete(*group.__inputs__)
        elsif group.read_other_nodes.empty?
          msg = <<~ERROR.squish
            Failed to delete group #{group.name} as the following primary nodes
            are still within it:
          ERROR
          raise InvalidAction, <<~ERROR.chomp
            #{msg}
            #{group.read_primary_nodes.map(&:name).join(',')}
          ERROR
        else
          msg = <<~ERROR.squish
            Failed to delete group #{group.name} as the following other nodes
            are still within it:
          ERROR
          raise InvalidAction, <<~ERROR.chomp
            #{msg}
          #{group.read_other_nodes.map(&:name).join(',')}
          ERROR
        end
      end
    end
  end
end
