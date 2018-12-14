# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name, :template, :parent_name

      def run
        @template = argv[0]
        @name = argv[1]
        @parent_name = options.parent
        deployment.deploy
      end

      private

      def parent_deployment
        return unless parent_name
        Models::Deployment.new(name: parent_name)
      end

      def deployment
        Models::Deployment.new(
          template_name: template,
          name: name,
          parent: parent_deployment
        )
      end
      memoize :deployment
    end
  end
end
