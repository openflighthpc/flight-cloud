# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name, :template

      def run
        @template = argv[0]
        @name = argv[1]
        deployment.deploy
      end

      private

      def deployment
        Models::Deployment.new(
          template_name: template,
          name: name,
          provider: 'aws'
        )
      end
      memoize :deployment
    end
  end
end
