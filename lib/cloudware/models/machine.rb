# frozen_string_literal: true

require 'models/application'
require 'models/concerns/provider_client'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient
      include Concerns::Tags

      TAG_TYPE = 'NODE'
      PROVIDER_ID_FLAG = 'ID'

      attr_accessor :name, :deployment

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :deployment

      def provider_id
        id_tag = self.class.tag_generator(name, PROVIDER_ID_FLAG)
        (deployment.results || {})[id_tag].tap do |id|
          raise ModelValidationError, <<-ERROR.squish unless id
            Machine '#{name}' is missing its provider ID. Make sure
            '#{id_tag}' is set within the deployment output
          ERROR
        end
      end

      private

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
