# frozen_string_literal: true

module Cloudware
  module Providers
    class AWS
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
