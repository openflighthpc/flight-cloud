
module Cloudware
  module Providers
    module DeployAWS
      private

      def deploy_aws
        cloud_formation.create_stack(
          stack_name: name,
          template_body: deploy_template_content,
          parameters: deploy_parameters
        )
        cloud_formation.wait_until(:stack_create_complete, stack_name: name)
      end

      def destroy
        cloud_formation(stack_name: name)
        cloud_formation(:stack_delete_complete, stack_name: name)
      end

      def cloud_formation
        @cloud_formation ||= Aws::CloudFormation::Client.new(
          region: region,
          credentials: Cloudware.config.credentials.aws,
        )
      end
    end
  end
end
