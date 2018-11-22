# frozen_string_literal: true

require 'models/application'
require 'models/machine'
require 'providers/AWS'

module Cloudware
  module Models
    class Deployment < Application
      attr_accessor :template_name, :name, :parent
      delegate :region, :provider, to: Config

      def template
        return raw_template unless parent
        parent.results.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value)
        end
      end

      def deploy
        raw_results = provider_client.deploy(tag, template)
        Data.dump(results_path, raw_results)
      end

      def destroy
        FileUtils.rm_f(results_path)
        provider_client.destroy(tag)
      end

      def results
        Data.load(results_path)
      end
      memoize :results

      def machines
        results.select { |k, _| Machine.tag?(k) }
               .map do |key, _|
          Machine.new(tag: key.to_s, deployment: self)
        end
      end

      private

      def provider_client
        Providers::AWS.new(region)
      end
      memoize :provider_client

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

      def results_path
        File.join(Config.content_path, 'deployments', "#{name}.yaml")
      end

      def raw_template
        File.read(template_path)
      end
    end
  end
end
