# frozen_string_literal: true

module Cloudware
  module Models
    class Context < Application
      def deployments
        stack.map(&:deployment)
      end

      def deployments=(input_deployments)
        @stack = [] # Reset the cache
        input_deployments.each do |deployment|
          add_deployment(deployment)
        end
      end

      def results
        stack.map(&:results)
             .each_with_object({}) do |results, memo|
          memo.merge!(results || {})
        end
      end

      def add_deployment(deployment)
        new_data = DeploymentData.new(deployment.name,
                                      deployment.results)
        stack.push(new_data)
      end

      def remove_deployment(deployment)
        stack.delete_if { |d| d.name == deployment.name }
      end

      def save
        save_data = stack.map(&:to_h)
        Data.dump(path, save_data)
      end

      private

      DeploymentData = Struct.new(:name, :results) do
        def deployment
          Deployment.new(name: name, results: results)
        end
      end

      def stack
        @stack ||= Data.load(path, default_value: []).map do |data|
          DeploymentData.new(*data.values)
        end
      end

      def path
        File.join(Config.content_path, 'contexts/default.yaml')
      end
    end
  end
end
