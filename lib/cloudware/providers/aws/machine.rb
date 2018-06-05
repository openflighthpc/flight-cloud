
module Cloudware
  module Providers
    module AWS
      class Machine < Base::Machine
        include DeployAWS

        attr_accessor :state

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

        def deployment_parameters
          super.merge(
            vmRole: role,
            networkId: domain.network_id,
            priSubnetId: domain.prisubnet_id,
            priSubnetCidr: domain.prisubnetcidr
          ).tap do |p|
            p.merge(clusterIndex: cluster_index) if cluster_index
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
