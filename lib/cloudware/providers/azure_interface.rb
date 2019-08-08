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

require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'cloudware/providers/base'

module Cloudware
  module Providers
    module AzureInterface
      class Credentials < Base::Credentials
        def self.build
          required_keys.map { |k| [k, config.public_send(k)] }.to_h
        end

        def self.required_keys
          [
            :subscription_id,
            :tenant_id,
            :client_id,
            :client_secret,
            :default_region
          ]
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

        def modify_instance_type(type)
          hardware_profile = Azure::Compute::Profiles::Latest::Mgmt::Models::HardwareProfile.new
          hardware_profile.vm_size = type

          vm_params = Azure::Compute::Profiles::Latest::Mgmt::Models::VirtualMachine.new
          vm_params.hardware_profile = hardware_profile

          compute_client.virtual_machines.update(*name_inputs, vm_params)
        rescue MsRestAzure::AzureOperationError
          raise ProviderError, 'Please enter a valid instance type'
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
          # NOTE: This is a different client then below
          klass = Azure::Compute::Profiles::Latest::Mgmt::Client
          klass.new(credentials)
        end
      end

      class Client < Base::Client
        MGMT_CLASS = Azure::Resources::Profiles::Latest::Mgmt

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
              p.mode = MGMT_CLASS::Models::DeploymentMode::Complete
            end
          end
        end

        def resource_client
          MGMT_CLASS::Client.new(credentials)
        end
        memoize :resource_client
      end
    end
  end
end
