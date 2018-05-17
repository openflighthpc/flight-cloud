
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
            pp instances
          end

          private

          attr_reader :region, :ec2

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
