
module Cloudware
  module Providers
    module Domains
      class AWS < Domain
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
              parameter_value: prisubnetcidr
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
