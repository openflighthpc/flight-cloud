# frozen_string_literal: true

require 'models/application'
require 'models/concerns/provider_client'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient

      NODE_PREFIX = 'cloudwareNODE'
      TAG_FLAG = 'TAG'

      PROVIDER_ID_FLAG = 'ID'

      class << self
        def build_from_deployment(deployment)
          (deployment.results || {})
                     .keys
                     .map { |k| Machine.name_from_tag(k) }
                     .uniq
                     .reject { |n| n.nil? }
                     .map do |name|
            Machine.new(name: name, deployment: deployment)
          end
        end

        def name_from_tag(tag)
          regex = /(?<=\A#{NODE_PREFIX}).*(?=#{TAG_FLAG}.*\Z)/
          regex.match(tag.to_s)&.to_a&.first
        end

        def tag_generator(name, tag)
          :"#{NODE_PREFIX}#{name}#{TAG_FLAG}#{tag}"
        end
      end

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
