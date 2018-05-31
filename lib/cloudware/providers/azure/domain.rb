# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Domain < Base::Domain
        def provider
          'azure'
        end

        def resource_group_name
          "alces-flightconnector-#{name}"
        end

        private

        include Helpers::Client
        include Helpers::Deploy

        def deployment_parameters
          {
            cloudwareDomain: name,
            cloudwareId: id,
            networkCIDR: networkcidr,
            priSubnetCIDR: prisubnetcidr
          }
        end

        def run_destroy
          client.resource.resource_groups.delete(resource_group_name)
        end

        def resource_group
          group = client.resource.model_classes.resource_group.new
          group.location = region
          group.tags = {
            cloudware_id: id,
            cloudware_domain: name,
            region: region
          }
          client.resource.resource_groups
                .create_or_update(resource_group_name, group)
        end
        memoize :resource_group

        def template_path
          File.join(
            Cloudware.config.base_dir,
            "providers/azure/templates/#{template}.json"
          )
        end
      end
    end
  end
end
