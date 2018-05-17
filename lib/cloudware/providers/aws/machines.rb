
# frozen_string_literal: true

module Cloudware
  module Providers
    module AWS
      class Machines < Base::Machines
        class Builder
          def initialize(region)
            @region ||= region
            @ec2 = Aws::EC2::Client.new(
              region: region,
              credentials: Cloudware.config.credentials.aws
            )
          end

          def models
            instances.map { |i| build_machine(i) }
          end

          private

          attr_reader :region, :ec2

          def build_machine(instance)
            tags = tags_structs(instance.tags)
            Models::Machine.build(
              state: instance.state.name,
              extip: instance.public_ip_address,
              provider_type: instance.instance_type,
              instance_id: instance.instance_id,
              domain: domains.find_by_name(tags.cloudware_domain),
              id: tags.cloudware_id,
              role: tags.cloudware_machine_role,
              priip: tags.cloudware_pri_subnet_ip,
              name: tags.cloudware_machine_name,
              flavour: tags.cloudware_machine_flavour
            )
          end

          def instances
            @instances ||= begin
              ec2.describe_instances(
                filters: [{ name: 'tag-key', values: ['cloudware_id'] }]
              ).reservations
               .map(&:instances)
               .flatten
               .reject { |i| i.state.name == 'terminated' }
            end
          end

          def domains
            @domains ||= AWS::Domains.by_region(region)
          end

          def tags_structs(tags_struct)
            OpenStruct.new(
              tags_struct.map { |t| [t.key, t.value] }.to_h
            )
          end
        end
      end
    end
  end
end
