# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Destroy < Command
      attr_reader :name

      def run
        @name = argv[0]
        deployment.destroy
      end

      private

      def deployment
        Models::Deployment.new(name: name)
      end
      memoize :deployment
    end
  end
end
