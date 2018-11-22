# frozen_string_literal: true

require 'models/application'
require 'models/concerns/provider_client'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient

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

      def provider_id
        deployment.results[tag.to_sym]
      end

      def status
      end
    end
  end
end
