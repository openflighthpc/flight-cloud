# frozen_string_literal: true

require 'providers/base'

module Cloudware
  module Providers
    module AWS
      class Machine < Base::Machine
        def status
          instance.state.name
        end

        def off
          instance.stop
        end

        def on
          instance.start
        end

        private

        def instance
          Aws::EC2::Resource.new(region: region)
                            .instance(machine_id)
        end
        memoize :instance
      end

      class Client < Base::Client
        def deploy(tag, template)
          client.create_stack(stack_name: tag, template_body: template)
          client.wait_until(:stack_create_complete, stack_name: tag)
                .stacks
                .first
                .outputs
                .reduce({}) do |memo, output|
                  memo[output.output_key] = output.output_value
                  memo
                end
        end

        def destroy(tag)
          client.delete_stack(stack_name: tag)
          client.wait_until(:stack_delete_complete, stack_name: tag)
        end

        private

        def client
          Aws::CloudFormation::Client.new(
            region: region,
            credentials: Config.credentials.aws
          )
        end
        memoize :client
      end
    end
  end
end
