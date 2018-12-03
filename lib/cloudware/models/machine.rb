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
      GROUPS_TAG = 'groups'

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :deployment

      def provider_id
        fetch_result(PROVIDER_ID_FLAG).tap do |long_tag|
          raise ModelValidationError, <<-ERROR.squish
            Machine '#{name}' is missing its provider ID. Make sure
            '#{long_tag}' is set within the deployment output
          ERROR
        end
      end

      def groups
        fetch_result(GROUPS_TAG, default: '').split(',')
      end

      private

      def fetch_result(short_tag, default: nil)
        long_tag = self.tag_generator(short_tag)
        result = (deployment.results || {})[long_tag]
        return result unless result.nil?
        return default unless default.nil?
        yield long_tag if block_given?
      end

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
