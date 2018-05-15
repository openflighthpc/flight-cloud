# frozen_string_literal: true

module Cloudware
  module Providers
    module AWS
      class Domain < Providers::Domain
        class << self
          def by_region(region)
            ec2_by_region(region).describe_vpcs(
              filters: [{ name: 'tag-key', values: ['cloudware_id'] }]
            ).vpcs.map { |vpc| build_domain(region, vpc) }
          end

          private

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

        include DeployAWS

        def create
          deploy_aws
        rescue Aws::CloudFormation::Errors::AlreadyExistsException
          domain_model.create_domain_already_exists_flag = true
          domain_model.valid?
        end

        private

        def id
          @id ||= SecureRandom.uuid
        end

        def deploy_parameters
          [
            { parameter_key: 'cloudwareDomain', parameter_value: name },
            { parameter_key: 'cloudwareId', parameter_value: id },
            { parameter_key: 'networkCidr', parameter_value: networkcidr },
            {
              parameter_key: 'priSubnetCidr',
              parameter_value: prisubnetcidr,
            },
          ]
        end

        def deploy_template_content
          path = File.join(
            Cloudware.config.base_dir,
            "providers/aws/templates/#{template}.yml"
          )
          File.read(path)
        end
      end
    end
  end
end
