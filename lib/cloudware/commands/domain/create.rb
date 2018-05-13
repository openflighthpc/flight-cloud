# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Create < Command
        def run
          d = Cloudware::Models::Domain.build(
            name: name,
            region: options.region,
            provider: options.provider,
            networkcidr: options.networkcidr,
            prisubnetcidr: options.prisubnetcidr
          )

          run_whirly('Checking domain does not already exist') do |update_status|
            raise("Domain name #{options.name} already exists") if d.exists?
          end

          run_whirly('Creating new deployment') do
            d.create!
          end
        end

        def unpack_args
          @name = args.first
        end

        def required_options
          [:provider, :region]
        end

        private

        attr_reader :name
      end
    end
  end
end
