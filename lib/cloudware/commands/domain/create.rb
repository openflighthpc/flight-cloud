# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Create < Command
        include Concerns::DomainInput

        def run
          run_whirly('Creating new domain') do
            Providers.select(options.provider)::Domain.build(
              name: name,
              region: options.region,
              networkcidr: options.networkcidr,
              prisubnetcidr: options.prisubnetcidr,
              template: options.template,
              cluster_index: options.cluster_index
            ).create!
          end
        end
      end
    end
  end
end
