# frozen_string_literal: true

module Cloudware
  module Providers
    class AWS
      extend Memoist

      attr_reader :region

      def initialize(region)
        @region = region
      end

      def deploy(name, template)
        client.create_stack(stack_name: name, template_body: template)
        client.wait_until(:stack_create_complete, stack_name: name)
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
