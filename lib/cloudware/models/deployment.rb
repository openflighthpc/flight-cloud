# frozen_string_literal: true

require 'models/application'
require 'providers/AWS'

module Cloudware
  module Models
    class Deployment < Application
      attr_accessor :template_name, :name, :parent
      delegate :region, :provider, to: Config

      def tag_name
        "cloudware-deploy-#{name}"
      end

      def path
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join(
          Config.content_path,
          'templates',
          provider,
          "#{template_name}#{ext}"
        )
      end

      def template
        File.read(path)
      end

      def deploy
        raw_results = Providers::AWS.new(region).deploy(tag_name, template)
        Data.dump(results_path, raw_results)
      end

      def results
        Data.load(results_path)
      end

      def results_path
        File.join(Config.content_path, 'deployments', "#{name}.yaml")
      end
    end
  end
end
