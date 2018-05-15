
# frozen_string_literal: true

module Cloudware
  module Providers
    module DeployAWS
      def destroy
        cloud_formation.delete_stack(stack_name: name)
        cloud_formation.wait_until(:stack_delete_complete, stack_name: name)
      end

      private

      def deploy_aws
        cloud_formation.create_stack(
          stack_name: name,
          template_body: deploy_template_content,
          parameters: deploy_parameters
        )
        cloud_formation.wait_until(:stack_create_complete, stack_name: name)
      end

      def cloud_formation
        @cloud_formation ||= Aws::CloudFormation::Client.new(
          region: region,
          credentials: Cloudware.config.credentials.aws
        )
      end
    end
  end
end
