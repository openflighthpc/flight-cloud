# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        include Concerns::DomainInput

        def run
          run_whirly("Destroying domain #{options.name}") do
            Providers.select(options.provider)::Domain.new(
              name: name,
              region: options.region
            ).destroy!
          end
        end
      end
    end
  end
end
