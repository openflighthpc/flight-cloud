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
            parameters: convert_deployment_parameters_to_aws_syntax
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
        # AWS does not play well with non-string inputs. Instead all values
        # are passed as strings which can then be converted in the template
        def convert_deployment_parameters_to_aws_syntax
          deployment_parameters.map do |k, v|
            { parameter_key: k.to_s , parameter_value: v.to_s }
          end
        end
      end
    end
  end
end
