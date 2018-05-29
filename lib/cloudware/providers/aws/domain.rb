# frozen_string_literal: true

module Cloudware
  module Providers
    module AWS
      class Domain < Base::Domain
        include DeployAWS

        attr_accessor :network_id, :prisubnet_id

        def run_create
          deploy_aws
        rescue Aws::CloudFormation::Errors::AlreadyExistsException
          self.create_domain_already_exists_flag = true
          valid?
        end

        def provider
          'aws'
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
          ].tap do |p|
            if cluster_index
              p << {
                parameter_key: 'clusterIndex',
                parameter_value: cluster_index,
              }
            end
          end
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
