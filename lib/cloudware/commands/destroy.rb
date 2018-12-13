# frozen_string_literal: true


require 'models/deployment'

module Cloudware
  module Commands
    class Destroy < Command
      attr_reader :name

      def run
        @name = argv[0]
        with_spinner('Destroying resources...', done: 'Done') do
          deployment.destroy
        end
      ensure
        context.save
      end

      private

      def deployment
        Models::Deployment.new(name: name, context: context)
      end
      memoize :deployment
    end
  end
end
