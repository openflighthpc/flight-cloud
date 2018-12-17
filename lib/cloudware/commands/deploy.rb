# frozen_string_literal: true

require 'models/deployment'
require 'parse_param'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name, :template_path

      def run
        @name = argv[0]
        @template_path = argv[1]
        begin
          with_spinner('Deploying resources...', done: 'Done') do
            deployment.deploy
          end
        ensure context.save
        end
      end

      private

      def deployment
        Models::Deployment.new(
          template_path: template_path,
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
