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
        context.find_deployment(name).tap do |deployment|
          if deployment.nil?
            raise InvalidInput, <<~ERROR.chomp
  Could not find deployment '#{name}'
            ERROR
          end
        end
      end
    end
  end
end
