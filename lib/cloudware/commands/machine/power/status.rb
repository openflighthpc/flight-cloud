# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      module Power
        class Status < Command
          def run
            machine = run_whirly('Fetching machine') do
              Providers.find_machine(
                options.provider,
                options.region,
                options.domain,
                name,
                missing_error: true
              )
            end
            puts "#{name}: Power status is #{machine.state}"
          end

          private

          attr_reader :name

          def required_options
            [:domain]
          end

          def unpack_args
            @name = args.first
          end
        end
      end
    end
  end
end
