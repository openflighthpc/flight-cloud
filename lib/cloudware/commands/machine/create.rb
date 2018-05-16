# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Create < Command
        def run
          m = Cloudware::Machine.new
          d = Cloudware::Domain.new

          m.type = options.type.to_s
          m.flavour = options.flavour.to_s
          m.name = name

          m.domain = options.domain
          d.name = options.domain

          m.role = options.role

          options.priip = ask('Pri subnet IP: ') if options.priip.nil?
          m.priip = options.priip.to_s

          run_whirly('Verifying domain exists') do
            raise("Domain #{options.domain} does not exist") unless m.valid_domain?
          end

          run_whirly('Checking machine name is valid') do |update_status|
            raise("Machine name #{options.name} is not a valid machine name") unless m.validate_name?
            update_status.call('Verifying pri IP address')
            raise("Invalid pri IP address #{options.priip} in subnet #{d.get_item('pri_subnet_cidr')}") unless m.valid_ip?(d.get_item('pri_subnet_cidr').to_s, options.priip.to_s)
          end

          run_whirly('Creating new deployment') do
            m.create
          end
        end

        def unpack_args
          @name = args.first
        end

        private

        attr_reader :name

        def required_options
          [:domain, :role]
        end
      end
    end
  end
end
