# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Power < Command
        attr_reader :identifier

        def run
          @identifier = argv[0]
          machines.each { |m| run_power_command(m) }
        end

        def run_power_command(_machine)
          raise NotImplementedError
        end

        private

        def machines
          if options.group
            Models::Machine.build_from_context(context)
                           .select { |m| m.groups.include?(identifier) }
          else
            [Models::Machine.new(name: identifier, context: context)]
          end
        end
        memoize :machines
      end
    end
  end
end
