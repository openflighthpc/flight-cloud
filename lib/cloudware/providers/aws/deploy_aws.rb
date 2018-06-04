# frozen_string_literal: true

module Cloudware
  module Providers
    module AWS
      module DeployAWS
        def run_destroy
          cloud_formation.delete_stack(stack_name: name)
          cloud_formation.wait_until(:stack_delete_complete, stack_name: name)
        end

        private

        def deploy_aws
          cloud_formation.create_stack(
            stack_name: name,
            template_body: deploy_template_content,
            parameters: convert_deploy_parameters_to_aws_syntax
          )
          cloud_formation.wait_until(:stack_create_complete, stack_name: name)
        end

        def cloud_formation
          @cloud_formation ||= Aws::CloudFormation::Client.new(
            region: region,
            credentials: Cloudware.config.credentials.aws
          )
        end

        # This methods allows the parameters to be defined as a hash then
        # converted to the syntax required by aws
        def convert_deploy_parameters_to_aws_syntax
          deploy_parameters.map do |k, v|
            { parameter_key: k.to_s , parameter_value: v }
          end
        end
      end
    end
  end
end
