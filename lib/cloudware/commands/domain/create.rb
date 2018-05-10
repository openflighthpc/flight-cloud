# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Create < Command
        def run
          d = Cloudware::Domain.new

          options.name = ask('Domain identifier: ') if options.name.nil?
          d.name = options.name.to_s

          options.provider = choose('Provider name?', :aws, :azure, :gcp) if options.provider.nil?

          options.region = ask('Provider region: ') if options.region.nil?
          d.region = options.region.to_s

          options.networkcidr = ask('Network CIDR: ') if options.networkcidr.nil?
          d.networkcidr = options.networkcidr.to_s

          options.prvsubnetcidr = ask('Prv subnet CIDR: ') if options.prvsubnetcidr.nil?
          d.prvsubnetcidr = options.prvsubnetcidr.to_s

          options.mgtsubnetcidr = ask('Mgt subnet CIDR: ') if options.mgtsubnetcidr.nil?
          d.mgtsubnetcidr = options.mgtsubnetcidr.to_s

          Whirly.start spinner: 'dots2', status: 'Verifying network CIDR is valid'.bold, stop: '[OK]'.green
          raise("Network CIDR #{options.networkcidr} is not a valid IPV4 address") unless d.valid_cidr?(options.networkcidr.to_s)
          Whirly.status = 'Verifying prv subnet CIDR is valid'.bold
          raise("Prv subnet CIDR #{options.prvsubnetcidr} is not valid for network cidr #{options.networkcidr}") unless d.is_valid_subnet_cidr?(options.networkcidr.to_s, options.prvsubnetcidr.to_s)
          Whirly.status = 'Verifying mgt subnet CIDR is valid'.bold
          raise("Mgt subnet CIDR #{options.mgtsubnetcidr} is not valid for network cidr #{options.networkcidr}") unless d.is_valid_subnet_cidr?(options.networkcidr.to_s, options.mgtsubnetcidr.to_s)
          Whirly.stop

          Whirly.start spinner: 'dots2', status: 'Checking domain name is valid'.bold, stop: '[OK]'.green
          raise("Domain name #{options.name} is not valid") unless d.valid_name?
          Whirly.stop

          Whirly.start spinner: 'dots2', status: 'Checking domain does not already exist'.bold, stop: '[OK]'.green
          raise("Domain name #{options.name} already exists") if d.exists?
          d.provider = options.provider.to_s
          Whirly.status = 'Verifying provider is valid'.bold
          raise("Provider #{options.provider} does not exist") unless d.valid_provider?
          Whirly.stop

          Whirly.start spinner: 'dots2', status: 'Creating new deployment'.bold, stop: '[OK]'.green
          d.create
          Whirly.stop
        end
      end
    end
  end
end
