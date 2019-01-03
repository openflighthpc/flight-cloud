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

require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'cloudware/providers/base'

module Cloudware
  module Providers
    module AzureInterface
      MGMT_CLASS = Azure::Resources::Profiles::Latest::Mgmt

      class Credentials < Base::Credentials
        def self.build
          {
            subscription_id: config.subscription_id,
            tenant_id: config.tenant_id,
            client_id: config.client_id,
            client_secret: config.client_secret,
          }
        end

        private_class_method

        def self.config
          Config.azure
        end
      end

      class Machine < Base::Machine
        STATE_REGEX = /PowerState\//

        def status
          compute_client.virtual_machines
                        .instance_view(*name_inputs)
                        .statuses
                        .reverse
                        .find { |s| STATE_REGEX.match?(s.code) }
                        .code
                        .sub(STATE_REGEX, '')
        end

        def off
          compute_client.virtual_machines.power_off(*name_inputs)
        end

        def on
          compute_client.virtual_machines.start(*name_inputs)
        end

        private

        def name_inputs
          [resource_group_name, machine_name]
        end

        def resource_group_name
          /(?<=\/resourceGroups\/)[^\/]*/.match(machine_id).to_a.first
        end

        def machine_name
          /(?<=\/virtualMachines\/).*/.match(machine_id).to_a.first
        end

        def compute_client
          klass = Azure::Compute::Profiles::Latest::Mgmt::Client
          klass.new(credentials)
        end
      end

      class Client < Base::Client
        def deploy(name, template)
          group = create_resource_group(name)
          deployment = build_deployment(template)
          resource_client.deployments
                         .create_or_update(group.name, name, deployment)
                         .properties
                         .outputs
                         .map { |k, v| [k.to_sym, v['value']] }
                         .to_h
        end

        def destroy(name)
          rg_name = resource_group_name(name)
          resource_client.resource_groups.delete(rg_name)
        end

        private

        def resource_group_name(name)
          "#{name}-rg"
        end

        def create_resource_group(name)
          rg_name = resource_group_name(name)
          group = resource_client.model_classes.resource_group.new
          group.location = region
          resource_client.resource_groups.create_or_update(rg_name, group)
        end

        def build_deployment(template)
          resource_client.model_classes.deployment.new.tap do |d|
            d.properties = resource_client.model_classes.deployment_properties
                                          .new.tap do |p|
              p.template = JSON.parse(template)
              p.mode = Azure::Resources::Profiles::Latest::Mgmt::Models::DeploymentMode::Complete
            end
          end
        end

        def resource_client
          klass = Azure::Resources::Profiles::Latest::Mgmt::Client
          klass.new(credentials)
        end
        memoize :resource_client
      end
    end
  end
end
