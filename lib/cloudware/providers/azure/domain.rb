# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Domain < Base::Domain
        include Helpers::Deploy

        def provider
          'azure'
        end

        private

        include Helpers::Client

        def deployment_parameters
          {
            cloudwareDomain: name,
            cloudwareId: id,
            networkCIDR: networkcidr,
            priSubnetCIDR: prisubnetcidr
          }
        end

        def resource_group_name
          "alces-flightconnector-#{name}"
        end

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
