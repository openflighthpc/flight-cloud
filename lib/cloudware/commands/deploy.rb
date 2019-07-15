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

require 'cloudware/list_templates'
require 'tty-prompt'

module Cloudware
  module Commands
    class Deploy < Command
      def self.delayed_require
        super
        require 'cloudware/models/node'
        require 'cloudware/replacement_factory'
      end

      def run!(identifier)
        identifier == 'domain' ? domain : node(identifier)
      end

      # TODO: Handle dependent deployments at some point
      def node(identifier)
        node = Models::Node.prompt!(__config__.current_cluster, identifier)
        raise_if_deployed(node)
        deployed_node = with_spinner('Deploying node...', done: 'Done') do
          Models::Node.deploy!(__config__.current_cluster, identifier)
        end
        if deployed_node.deployment_error
          raise DeploymentError, <<~ERROR.chomp
             An error has occured. Please see for further details:
            `#{Config.app_name} list --verbose`
          ERROR
        end
      end

      # TODO: DRY This up with above
      def domain
        domain = Models::Domain.prompt!(__config__.current_cluster)
        raise_if_deployed(domain)
        deployed_domain = with_spinner('Deploying domain...', done: 'Done') do
          Models::Domain.deploy!(__config__.current_cluster)
        end
        if deployed_domain.deployment_error
          raise DeploymentError, <<~ERROR.chomp
            An error has occurred deploying the domain.
            `#{Config.app_name} list --verbose`
          ERROR
        end
      end

      def render(name)
        dep = if name == 'domain'
                Models::Domain.prompt!(__config__.current_cluster)
              else
                Models::Node.prompt!(__config__.current_cluster, name)
              end
        puts dep.template
      end

      private

      # TODO: If this code is still commented out in a few months, feel free to delete it
      # def create_deployment(name, raw_path, params: nil)
      #   replacements = ReplacementFactory.new(__config__.current_cluster, name)
      #                                    .build(params)
      #   Models::Deployment.create!(
      #     __config__.current_cluster, name,
      #     template: raw_path,
      #     replacements: replacements
      #   ) { |errors| prompt_for_params(errors) }
      # end

      def raise_if_deployed(dep)
        return unless dep.deployed
        raise InvalidInput, "'#{dep.name}' is already running"
      end

      def deploy(machine)
        with_spinner('Deploying resources...', done: 'Done') do
          dep = Models::Deployment.deploy!(__config__.current_cluster, machine)
          if dep.deployment_error
            raise DeploymentError, <<~ERROR.chomp
               An error has occured. Please see for further details:
              `#{Config.app_name} list --verbose`
            ERROR
          end
        end
      end
    end
  end
end
