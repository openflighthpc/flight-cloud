
# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Domains < Base::Domains
        class Builder
          NETWORK_TYPE = 'Microsoft.Network/virtualNetworks'

          extend Memoist
          include Helpers::Client

          def initialize(region)
            @region ||= region
          end

          def domains
            domain_resources.map { |r| build_domain(r) }
          end
          memoize :domains

          private

          attr_reader :region

          def resource_groups
            client.resource.resource_groups.list.select do |rg|
              rg.location == region
            end
          end

          def domain_resources
            groups = resource_groups.map do |group|
              client.resource.resources.list_by_resource_group(group.name)
            end.flatten
            groups.select do |resource|
              next false unless resource.type == NETWORK_TYPE
              resource.tags&.[]('cloudware_domain')
            end
          end

          def build_domain(resource)
            tags = OpenStruct.new(resource.tags)
            Domain.build(
              name: tags.cloudware_domain,
              id: tags.id,
              networkcidr: tags.cloudware_network_cidr,
              prisubnetcidr: tags.cloudware_pri_subnet_cidr,
              region: region
            )
          end
        end

        class << self
          private

          def domain_models_by_region(region)
            Builder.new(region).domains
          end
        end
      end
    end
  end
end