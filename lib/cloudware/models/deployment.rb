# frozen_string_literal: true

require 'models/concerns/provider_client'
require 'models/application'
require 'models/machine'
require 'providers/AWS'

module Cloudware
  module Models
    class Deployment < Application
      include Concerns::ProviderClient

      SAVE_ATTR = [:template_name, :name, :results]
      attr_accessor(*SAVE_ATTR, :context)
      delegate :region, :provider, to: Config

      def template
        return raw_template
        # TODO: Reimplement parents as a context
        # parent.results.reduce(raw_template) do |memo, (key, value)|
        #   memo.gsub("%#{key}%", value)
        # end
      end

      def deploy
        self.results = provider_client.deploy(tag, template)
      end

      def destroy
        provider_client.destroy(tag)
      end

      def machines
        results&.select { |k, _| Machine.tag?(k) }
               &.map do |key, _|
          Machine.new(tag: key.to_s, deployment: self)
        end
      end

      def to_h
        SAVE_ATTR.each_with_object({}) do |key, memo|
          memo[key] = send(key)
        end
      end

      private

      def tag
        "cloudware-deploy-#{name}"
      end

      def template_path
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join(
          Config.content_path,
          'templates',
          provider,
          "#{template_name}#{ext}"
        )
      end

      def raw_template
        File.read(template_path)
      end
    end
  end
end
