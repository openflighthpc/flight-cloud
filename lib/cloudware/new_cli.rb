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

require 'gli'

module Cloudware
  class NewCLI
    extend GLI::App

    subcommand_option_handling :normal
    sort_help :manually

    desc 'Manage the cluster'
    command :cluster do |cluster|
      cluster.desc 'Create the cluster'
      cluster.arg_name 'NAME'
      cluster.command(:create) { |c| c.action { puts 'Do something' } }
      cluster.command(:delete) {}
      cluster.command(:list) {}
      cluster.command(:show) {}
      cluster.command(:action) do |action|
        action.command(:deploy) {}
        action.command(:destory) {}
      end
      cluster.command(:template) do |template|
        template.command(:edit) {}
        template.command(:show) {}
        template.command(:render) {}
      end
      cluster.command(:parameters) do |parameters|
        parameters.command(:edit) {}
        parameters.command(:show) {}
      end
    end

    desc 'Manage the node'
    command(:node) do |node|
      node.command(:create) {}
      node.command(:delete) {}
      node.command(:list) {}
      node.command(:show) {}
      node.command(:edit) {}
      node.command(:update) {}
      node.command(:action) do |action|
        action.command(:'power-on') {}
        action.command(:'power-off') {}
        action.command(:'power-status') {}
        action.command(:deploy) {}
        action.command(:destory) {}
      end
      node.command(:template) do |template|
        template.command(:edit) {}
        template.command(:show) {}
        template.command(:render) {}
      end
      node.command(:parameters) do |parameters|
        parameters.command(:edit) {}
        parameters.command(:show) {}
      end
    end

    desc 'Manage the group'
    command(:group) do |group|
      group.command(:create) {}
      group.command(:delete) {}
      group.command(:list) {}
      group.command(:show) { |c| c.action { |*a| puts a } }

      group.flag 'members-in', desc: 'Run the action over the memebers in the group',
                               arg_name: 'GROUP'
      group.command(:action) {}
    end
  end
end

