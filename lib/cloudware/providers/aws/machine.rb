
module Cloudware
  module Providers
    module AWS
      class Machine < Base::Machine
        include DeployAWS

        def create
          deploy_aws
        end

        private

        def id
          @id ||= SecureRandom.uuid
        end

        def deploy_parameters
          [
            {
              parameter_key: 'cloudwareDomain',
              parameter_value: domain.name
            },
            { parameter_key: 'cloudwareId', parameter_value: id },
            { parameter_key: 'priIp', parameter_value: priip },
            { parameter_key: 'vmRole', parameter_value: role },
            { parameter_key: 'vmType', parameter_value: type },
            { parameter_key: 'vmName', parameter_value: name },
            {
              parameter_key: 'networkId',
              parameter_value: domain.network_id
            },
            {
              parameter_key: 'priSubnetId',
              parameter_value: domain.pri_subnet_id
            },
            {
              parameter_key: 'priSubnetCidr',
              parameter_value: domain.pri_subnet_cidr
            },
            { parameter_key: 'vmFlavour', parameter_value: flavour },
          ]
        end

        def deploy_template_content
          path = File.join(
            Cloudware.config.base_dir,
            "providers/aws/templates/machine-#{role}.yml"
          )
          File.read(path)
        end
      end
    end
  end
end
