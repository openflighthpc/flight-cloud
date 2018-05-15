
module Cloudware
  module Providers
    module AWS
      class Domains < Providers::Domains
        class << self
          private

          def domain_models_by_region(region)
            ec2_by_region(region).describe_vpcs(
              filters: [{ name: 'tag-key', values: ['cloudware_id'] }]
            ).vpcs.map { |vpc| build_domain(region, vpc) }
          end

          def ec2_by_region(region)
            Aws::EC2::Client.new(
              region: region,
              credentials: Cloudware.config.credentials.aws
            )
          end

          def build_domain(region, vpc)
            args = { provider: 'aws', region: region }
            Models::Domain.build(**args).tap do |domain|
              vpc.tags.each do |tag|
                case tag.key
                when 'cloudware_domain'
                  domain.name = tag.value
                when 'cloudware_network_cidr'
                  domain.networkcidr = tag.value
                when 'cloudware_pri_subnet_ip'
                  domain.prisubnetcidr = tag.value
                end
              end
            end
          end
        end
      end
    end
  end
end
