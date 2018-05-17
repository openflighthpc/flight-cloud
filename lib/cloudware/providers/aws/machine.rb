
module Cloudware
  module Providers
    module AWS
      class Machine < Base::Machine
        include DeployAWS

        def create
          deploy_aws
        end

        private

        def aws_type
          machine_mappings[flavour][type]
        end

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
            { parameter_key: 'vmType', parameter_value: aws_type },
            { parameter_key: 'vmName', parameter_value: name },
            {
              parameter_key: 'networkId',
              parameter_value: domain.network_id
            },
            {
              parameter_key: 'priSubnetId',
              parameter_value: domain.prisubnet_id
            },
            {
              parameter_key: 'priSubnetCidr',
              parameter_value: domain.prisubnetcidr
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

        def machine_mappings
          @machine_mappings ||= YAML.load_file(File.join(
            Cloudware.config.base_dir,
              "providers/aws/mappings/machine_types.yml"
          ))
        end
      end
    end
  end
end
