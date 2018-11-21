# frozen_string_literal: true

require 'models/application'
require 'providers/AWS'

module Cloudware
  module Models
    class Deployment < Application
      attr_accessor :template_name, :name
      delegate :region, :provider, to: Config

      def tag_name
        "cloudware-deploy-#{name}"
      end

      def path
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join('/var/lib/cloudware/templates', provider, template_name) + ext
      end

      def template
        File.read(path)
      end

      def deploy
        Providers::AWS.new(region).deploy(tag_name, template)
      end
    end
  end
end
