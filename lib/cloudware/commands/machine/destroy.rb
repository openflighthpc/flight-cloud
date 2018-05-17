# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Destroy < Command
        def run
          run_whirly("Destroying: '#{name}'") do
            Providers.find_machine(
              options.provider,
              options.region,
              name
            ).tap { |m| raise_if_machine_is_missing(m) }

          end
        end

        private

        attr_reader :name

        def unpack_args
          @name = args.first
        end

        def raise_if_machine_is_missing(machine)
          return if machine
          raise InvalidInput, "Could not find machine: '#{name}'"
        end
      end
    end
  end
end
