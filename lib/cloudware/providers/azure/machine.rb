module Cloudware
  module Providers
    module AZURE
      class Machine < Base::Machine
        STATE_REGEX = /PowerState\//

        include Helpers::Deploy

        def state
          client.compute.virtual_machines.instance_view(
            resource_group_name, name
          ).statuses
           .reverse
           .find { |s| STATE_REGEX.match?(s.code) }
           .code
           .sub(STATE_REGEX, '')
        end

        def power_on
          client.compute.virtual_machines.start(resource_group_name, name)
        end

        def power_off
          client.compute.virtual_machines.power_off(
            resource_group_name, name
          )
        end

        private

        include Helpers::Client

        def deployment_parameters
          super.merge(cloudwareDomainGroup: domain.resource_group.name)
        end

        def template_path
          File.join(
            Cloudware.config.base_dir,
            "providers/azure/templates/machine-#{role}.json"
          )
        end
      end
    end
  end
end
