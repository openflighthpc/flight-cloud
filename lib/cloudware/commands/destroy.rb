# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Destroy < Command
      attr_reader :name

      def run
        @name = argv[0]
        deployment.destroy
      ensure
        context.save
      end

      private

      def context
        Models::Context.new
      end
      memoize :context

      def deployment
        Models::Deployment.new(name: name, context: context)
      end
      memoize :deployment
    end
  end
end
