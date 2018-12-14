# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    class Info < Command
      include Concerns::Table
      attr_reader :name

      def run
        @name = argv[0]
        models.tags.each { |row| table << row }
        page_table
      end

      private

      def model_class
        raise NotImplementedError
      end

      def models
        model_class.new(name: name, context: context)
      end
      memoize :models

      def table_header
        ['Tag', 'Value']
      end
    end
  end
end
