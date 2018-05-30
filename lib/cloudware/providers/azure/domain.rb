# frozen_string_literal: true

require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'azure_mgmt_network'

module Cloudware
  module Providers
    module AZURE
      class Domain < Base::Domain
        def provider
          'azure'
        end

        private

        include Helpers::Client

        def run_create
          create_resource_group
        rescue MsRestAzure::AzureOperationError => e
          # Azure returns a `JSON` string which contains an embedded `JSON`
          # string. This embedded `JSON` contains the error message
          message = JSON.parse(
            JSON.parse(e.message)['response']['body']
          )['error']['message']
          raise InvalidAzureRequest, message
        end

        def id
          @id ||= SecureRandom.uuid
        end

        def create_resource_group
          client.resource.model_classes.resource_group.new.tap do |group|
            group.location = region
            group.tags = {
              cloudware_id: id,
              cloudware_domain: name,
              region: region
            }
            client.resource.resource_groups.create_or_update(name, group)
          end
        end

        def deployment_model
          client.resource.model_classes.deployment.new.tap do |deployment|
            deployment.properties = deployment_properties
          end
        end

        def deployment_properties
          client.resource.model_classes.deployment_properties do |props|
            props.template = template
            props.parameters = {
              cloudwareDomain: name,
              cloudwareId: id,
              networkCIDR: networkcidr,
              priSubnetCIDR: prisubnetcidr
            }
          end
        end
      end
    end
  end
end
