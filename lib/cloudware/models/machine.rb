# frozen_string_literal: true

require 'models/application'
require 'models/concerns/provider_client'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :deployment

      TAG_PREFIX = 'cloudwareNodeID'

      def self.tag?(tag)
        /\A#{TAG_PREFIX}/.match?(tag)
      end

      attr_accessor :name, :deployment

      def tag=(tag)
        self.name = tag.sub(TAG_PREFIX, '')
      end

      def tag
        "#{TAG_PREFIX}#{name}"
      end

      private

      def provider_id
        deployment.results[tag.to_sym]
      end

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
