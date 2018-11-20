# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name

      def run
        @name = argv[0]
        deployment.deploy
      end

      private

      def deployment
        Models::Deployment.new(name: name, provider: 'aws')
      end
      memoize :deployment
    end
  end
end
