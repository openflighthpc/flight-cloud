# frozen_string_literal: true

module Cloudware
  module Models
    class Context < Application
      def results
        stack.map(&:results)
             .each_with_object({}) do |results, memo|
          memo.merge!(results || {})
        end
      end

      def deployments
      end

      private

      DeploymentData = Struct.new(:name, :results)

      def stack
        @stack ||= deployments.map do |deployment|
          DeploymentData.new(deployment.name,
                             deployment.results)
        end
      end
    end
  end
end
