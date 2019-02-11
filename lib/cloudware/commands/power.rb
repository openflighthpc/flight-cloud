# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
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

module Cloudware
  module Commands
    module Powers
      class Power < Command
        attr_reader :identifier

        def run
          @identifier = argv[0]
          machines.each { |m| run_power_command(m) }
        end

        def run_power_command(_machine)
          raise NotImplementedError
        end

        private

        def machines
          if options.group
            Cluster.load(__config__.current_cluster)
                   .deployments
                   .machines
                   .select { |m| m.groups.include?(identifier) }
          else
            [Models::Machine.new(name: identifier, cluster: __config__.current_cluster)]
          end
        end
      end
    end
  end
end
