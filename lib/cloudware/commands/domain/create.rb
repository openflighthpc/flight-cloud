# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Create < Command
        def run
          d = Cloudware::Domain.new
          d.name = name
          d.region = options.region
          d.networkcidr = options.networkcidr
          d.prisubnetcidr = options.prisubnetcidr

          run_whirly('Verifying network CIDR is valid') do |update_status|
            raise("Network CIDR #{options.networkcidr} is not a valid IPV4 address") unless d.valid_cidr?(options.networkcidr.to_s)
            update_status.call('Verifying pri subnet CIDR is valid')
            raise("Pri subnet CIDR #{options.prisubnetcidr} is not valid for network cidr #{options.networkcidr}") unless d.is_valid_subnet_cidr?(options.networkcidr.to_s, options.prisubnetcidr.to_s)
            update_status.call('Verifying mgt subnet CIDR is valid')
          end

          run_whirly('Checking domain name is valid') do
            raise("Domain name #{options.name} is not valid") unless d.valid_name?
          end

          run_whirly('Checking domain does not already exist') do |update_status|
            raise("Domain name #{options.name} already exists") if d.exists?
            d.provider = options.provider.to_s
            update_status.call('Verifying provider is valid')
            raise("Provider #{options.provider} does not exist") unless d.valid_provider?
          end

          run_whirly('Creating new deployment') do
            d.create
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
