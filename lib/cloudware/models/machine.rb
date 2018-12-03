# frozen_string_literal: true

require 'models/application'
require 'models/concerns/provider_client'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient
      include Concerns::DeploymentTags

      TAG_TYPE = 'NODE'
      PROVIDER_ID_FLAG = 'ID'

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :deployment

      def provider_id
        fetch_result(PROVIDER_ID_FLAG).tap do |id|
          raise ModelValidationError, <<-ERROR.squish unless id
            Machine '#{name}' is missing its provider ID. Make sure
            '#{self.tag_generator(PROVIDER_ID_FLAG)}' is set within the
            deployment output
          ERROR
        end
      end

      private

      def fetch_result(short_tag)
        long_tag = self.tag_generator(short_tag)
        (deployment.results || {})[long_tag]
      end

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
