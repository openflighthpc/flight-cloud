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
      ensure
        context.save
      end

      private

      def context
        Models::Context.new
      end
      memoize :context

      def deployment
        Models::Deployment.new(
          template_name: template,
          name: name,
          context: context
        )
      end
      memoize :deployment

      def params
        options.params
      end
    end
  end
end
