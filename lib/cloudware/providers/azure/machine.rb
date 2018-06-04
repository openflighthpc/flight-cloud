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

        private

        include Helpers::Client

        def resource_group_name
          domain.resource_group.name + '-machine-' + name
        end

        def deployment_parameters
          {
            # TODO: Dafaq? Fix this
            cloudwareDomain: domain.resource_group.name,
            cloudwareId: id,
            vmName: name,
            vmType: provider_type,
            priSubnetIp: priip,
            vmFlavour: flavour,
          }
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
