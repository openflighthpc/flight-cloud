# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Rebuild < Command
        def run
          machine = run_whirly('Finding the machine') do
            Providers.find_machine(
              options.provider,
              options.region,
              name,
              missing_error: true
            )
          end
          run_whirly('Destroying the old machine') { machine.destroy! }
          run_whirly('Building the new machine') { machine.create! }
        end

        private

        attr_reader :name

        def unpack_args
          @name = args.first
        end
      end
    end
  end
end
