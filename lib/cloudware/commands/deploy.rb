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
          context: context,
          replacements: replacement_mapping
        )
      end
      memoize :deployment

      def replacement_mapping
        params.map do |replace_key, deployment_str|
          name, deployment_key = deployment_str.split('.', 2)
          results = context.find_by_name(name)&.results || {}
          raise InvalidInput, <<-ERROR.squish unless deployment_key
            '#{deployment_str}' must be in format: 'deployment.key'
          ERROR
          [replace_key, results[deployment_key]]
        end.to_h
      end

      def params
        (options.params || '').chomp.split.map do |param_str|
          param_str.split('=', 2).tap do |array|
            raise InvalidInput, <<-ERROR.squish unless array.length == 2
              '#{param_str}' does not form a key value pair
            ERROR
          end
        end.to_h.deep_symbolize_keys
      end
    end
  end
end
