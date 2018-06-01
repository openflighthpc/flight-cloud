module Cloudware
  module Providers
    module AZURE
      class Machine < Base::Machine
        include Helpers::Deploy

        private

        def resource_group_name
          domain.resource_group.name + '-machine-' + name
        end

        def deployment_parameters
          {
            cloudwareDomain: domain.name,
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
