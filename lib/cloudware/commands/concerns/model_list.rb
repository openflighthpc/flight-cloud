# frozen_string_literal: true

require 'commands/concerns/table'

module Cloudware
  module Commands
    module Concerns
      module ModelList
        extend Memoist
        include Concerns::Table

        def run
          add_rows
          page_table
        end

        private

        def deployment_method
          raise NotImplementedError
        end

        def models
          context.deployments
                 .map(&deployment_method)
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
          [deployment_method.to_s.capitalize, 'Deployment', *header_tags]
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
end
