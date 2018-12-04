# frozen_string_literal: true

require 'azure_mgmt_compute'
require 'providers/base'

module Cloudware
  module Providers
    module AZURE
      class Machine < Base::Machine
        STATE_REGEX = /PowerState\//

        def status
          compute_client.virtual_machines.instance_view(
            resource_group_name, machine_name
          ).statuses
           .reverse
           .find { |s| STATE_REGEX.match?(s.code) }
           .code
           .sub(STATE_REGEX, '')
        end

        private

        def resource_group_name
          /(?<=\/resourceGroups\/)[^\/]*/.match(machine_id).to_a.first
        end

        def machine_name
          /(?<=\/virtualMachines\/).*/.match(machine_id).to_a.first
        end

        def compute_client
          klass = Azure::Compute::Profiles::Latest::Mgmt::Client
          klass.new(Config.credentials.azure)
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
          klass.new(Config.credentials.azure)
        end
        memoize :resource_client
      end
    end
  end
end
