# frozen_string_literal: true

module Cloudware
  module Providers
    class AWS
      class Machine
        attr_reader :instance

        def initialize(machine_id, region)
          @instance = Aws::EC2::Resource.new(region: region)
                                        .instance(machine_id)
        end

        def status
          instance.state.name
        end

        def off
          instance.stop
        end
      end

      extend Memoist

      attr_reader :region

      def initialize(region)
        @region = region
      end

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

      def machine(id)
        Machine.new(id, region)
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
