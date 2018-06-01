module Cloudware
  module Providers
    module AZURE
      class Machine < Base::Machine
        delegate :resource_group, to: :domain

        private

        include Helpers::Deploy

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
