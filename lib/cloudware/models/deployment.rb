# frozen_string_literal: true

require 'models/application'

module Cloudware
  module Models
    class Deployment < Application
      attr_accessor :name, :provider

      def path
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join('/var/lib/cloudware/templates', provider, name) + ext
      end
    end
  end
end
