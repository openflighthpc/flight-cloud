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
    module Lists
      class Deployment < Command
        def self.delayed_require
          super
          require 'cloudware/templaters/deployment_templater'
        end

        def run!(verbose: false, all: false, group: nil)
          deps = deployments(group)
          deps = deps.select(&:deployed) unless all
          if deps.any?
            deps.each do |d|
              puts Templaters::DeploymentTemplater.new(d, verbose: verbose)
                                                  .render_info
            end
          elsif all
            $stderr.puts 'No deployments found'
          else
            $stderr.puts 'No running deployments. Use --all for all the deployments'
          end
        end

        def client_list
          hashify_list
        end

        private

        def hashify_list
          deployments(group)
            .each_with_object({ running: {}, offline: {} }) do |deployment, memo|
            status = deployment.deployed ? 'Running' : 'Offline'
            memo[status.downcase.to_sym][deployment.name] = {
              status: status,
              groups: (deployment.groups.join(',') if deployment.respond_to?(:groups))
            }
          end
        end

        def deployments(group)
          registry = FlightConfig::Registry.new
          [
            Models::Domain.read(__config__.current_cluster, registry: registry),
            *Models::Node.glob_read(__config__.current_cluster, '*', registry: registry)
          ].sort_by { |r| r.name }
            .select { |r| group ? (r.groups.include? group if r.respond_to?(:groups)) : r }
        end
      end
    end
  end
end
