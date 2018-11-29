# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Lists
      class Machine < Command
        include Concerns::Table

        def run
          add_rows
          puts render_table
        end

        private

        def machines
          Models::Context.new
                         .deployments
                         .map(&:machines)
                         .flatten
        end
        memoize :machines

        def header_tags
          machines.map { |m| m.tags.keys }
                  .flatten
                  .uniq
        end
        memoize :header_tags

        def table_header
          ['Machine', 'Deployment', *header_tags]
        end

        def add_rows
          machines.each do |machine|
            tags = machine.tags
            machine_values = header_tags.map { |k| tags[k] }
            table << [machine.name, machine.deployment.name, *machine_values]
          end
        end
      end
    end
  end
end
