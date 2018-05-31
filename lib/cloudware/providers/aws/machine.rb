
module Cloudware
  module Providers
    module AWS
      class Machine < Base::Machine
        include DeployAWS

        def power_on
          ec2.start_instances(
            instance_ids: [instance_id]
          )
        end

        def power_off
          ec2.stop_instances(
            instance_ids: [instance_id]
          )
        end

        private

        def run_create
          deploy_aws
        end

        def ec2
          @ec2 ||= Aws::EC2::Client.new(
            credentials: Cloudware.config.credentials.aws,
            region: region
          )
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
            { parameter_key: 'vmType', parameter_value: provider_type },
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
            "providers/aws/templates/machine-#{role}.yml"
          )
          File.read(path)
        end
      end
    end
  end
end
