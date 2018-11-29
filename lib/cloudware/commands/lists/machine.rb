# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Lists
      class Machine < Command
        def run
          puts header_tags
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
      end
    end
  end
end
