# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    class Info < Command
      include Concerns::ExistingDeployment
      include Concerns::Table
      attr_reader :name, :deployment_name

      def run
        @deployment_name = options.deployment
        @name = argv[0]
        models.tags.each { |row| table << row }
        puts render_table
      end

      private

      def model_class
        raise NotImplementedError
      end

      def models
        model_class.new(name: name, deployment: deployment)
      end
      memoize :models

      def table_header
        ['Tag', 'Value']
      end
    end
  end
end
