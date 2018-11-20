# frozen_string_literal: true

require 'models/application'
require 'providers/AWS'

module Cloudware
  module Models
    class Deployment < Application
      attr_accessor :name, :provider

      def tag_name
        "cloudware-deploy-#{name}"
      end

      # TODO: Set this in the same way as the original version
      def region
        'eu-west-1'
      end

      def path
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join('/var/lib/cloudware/templates', provider, name) + ext
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
