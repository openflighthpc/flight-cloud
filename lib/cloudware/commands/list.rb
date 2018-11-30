
# frozen_string_literal: true

module Cloudware
  module Commands
    class List < Command
      include Concerns::Table

      def run
        add_rows
        puts render_table
      end

      private

      def context_method
        raise NotImplementedError
      end

      def models
        Models::Context.new
                       .deployments
                       .map(&context_method)
                       .flatten
      end
      memoize :models

      def header_tags
        models.map { |m| m.tags.keys }
                .flatten
                .uniq
      end
      memoize :header_tags

      def table_header
        [context_method.to_s.capitalize, 'Deployment', *header_tags]
      end

      def add_rows
        models.each do |machine|
          tags = machine.tags
          machine_values = header_tags.map { |k| tags[k] }
          table << [machine.name, machine.deployment.name, *machine_values]
        end
      end
    end
  end
end
