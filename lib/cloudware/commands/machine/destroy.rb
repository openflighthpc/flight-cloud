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
              name,
              missing_error: true
            ).destroy!
          end
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
