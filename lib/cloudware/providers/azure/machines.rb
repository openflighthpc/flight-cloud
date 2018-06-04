
# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Machines < Base::Machines
        class Builder
          extend Memoist

          def initialize(region)
            @region ||= region
          end

          def models
            resources.map { |r| build_machine(r) }
          end
          memoize :models

          private

          include Helpers::Client

          attr_reader :region

          def domains
            Domains.by_region(region)
          end
          memoize :domains

          def resources
            client.resource.resources.list.select do |r|
              next unless r.tags
              next unless r.tags['cloudware_resource_type'] == 'machine'
              next unless r.type == 'Microsoft.Compute/virtualMachines'
              next unless r.location == region
              true
            end
          end
          memoize :resources

          def public_ipaddresses
            client.network.public_ipaddresses.list_all
          end
          memoize :public_ipaddresses

          def build_machine(resource)
            tags = OpenStruct.new(resource.tags)
            domain = domains.find do |d|
              d.resource_group.name == tags.cloudware_domain
            end
            name = tags.cloudware_machine_name
            public_ip = find_public_ip(domain, name)
            Machine.build(
              domain: domain,
              name: name,
              id: tags.cloudware_id,
              role: tags.cloudware_machine_role,
              priip: tags.cloudware_pri_ip,
              extip: public_ip.ip_address,
              provider_type: tags.cloudware_machine_type,
              flavour: tags.cloudware_machine_flavour
            )
          end

          def find_public_ip(domain, machine_name)
            public_ipaddresses.find do |ip|
              rg_name = domain.resource_group.name
              next unless ip.tags['cloudware_domain'] == rg_name
              ip.name == machine_name
            end
          end
        end
      end
    end
  end
end
