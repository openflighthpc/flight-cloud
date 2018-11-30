# frozen_string_literal: true

require 'models/deployment'
require 'parse_param'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name, :template

      def run
        @template = argv[0]
        @name = argv[1]
        error_if_deployment_exists
        begin deployment.deploy
        ensure context.save
        end
      end

      private

      def error_if_deployment_exists
        raise InvalidInput, <<-ERROR.squish if context.find_by_name(name)
          The '#{name}' deployment already exists
        ERROR
      end

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
        (options.params || '').chomp.split.map do |param_str|
          parser.string(param_str)
        end.to_h.merge(deployment_name: name)
      end

      def parser
        ParamParser.new(context)
      end
      memoize :parser
    end
  end
end
