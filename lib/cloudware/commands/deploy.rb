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
    class Deploy < ScopedCommand
      include WithSpinner

      def self.delayed_require
        require 'cloudware/models'
        require 'cloudware/models/node'
        require 'cloudware/replacement_factory'
      end

      def run!(params: nil)
        self.class.delayed_require
        dep_name = (model_klass == Models::Domain ? 'domain' : name_or_error)
        replacements = ReplacementFactory.new(config.current_cluster, dep_name)
                                         .build(params)
        model = model_klass.prompt!(replacements, *read_model.__inputs__)

        raise_if_deployed(model)

        deployed = with_spinner("Deploying #{model.name}...", done: 'Done') do
          model_klass.deploy!(*model.__inputs__)
        end

        if deployed.deployment_error
          raise DeploymentError, <<~ERROR.chomp
             An error has occured. Please see for further details:
            `#{Config.app_name} list --verbose`
          ERROR
        end
      end

      def render
        cur_model = model_klass.prompt!(nil, *read_model.__inputs__)
        puts cur_model.template
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
