# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Lists
      class Machine < Command
        def run
          puts machines
        end

        private

        def machines
          Models::Context.new
                         .deployments
                         .map(&:machines)
                         .flatten
        end
        memoize :machines
      end
    end
  end
end
