# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        include Concerns::DomainInput

        def run
          run_whirly("Destroying domain #{options.name}") do
            Models::Domain.new(
              name: name,
              provider: options.provider,
              region: options.region
            ).destroy!
          end
        end
      end
    end
  end
end
