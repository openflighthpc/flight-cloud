# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Create < Command
        def run
          options.default flavour: 'compute', type: 'small'

          m = Cloudware::Machine.new
          d = Cloudware::Domain.new

          m.type = options.type.to_s
          m.flavour = options.flavour.to_s

          options.name = ask('Machine name: ') if options.name.nil?
          m.name = options.name.to_s

          options.domain = ask('Domain identifier: ') if options.domain.nil?
          m.domain = options.domain.to_s
          d.name = options.domain.to_s

          options.role = choose('Machine role?', :master, :slave) if options.role.nil?
          m.role = options.role.to_s

          options.priip = ask('Pri subnet IP: ') if options.priip.nil?
          m.priip = options.priip.to_s

          Whirly.start status: 'Verifying domain exists'
          raise("Domain #{options.domain} does not exist") unless m.valid_domain?
          Whirly.stop

          Whirly.start status: 'Checking machine name is valid'
          raise("Machine name #{options.name} is not a valid machine name") unless m.validate_name?
          Whirly.status = 'Verifying pri IP address'
          raise("Invalid pri IP address #{options.priip} in subnet #{d.get_item('pri_subnet_cidr')}") unless m.valid_ip?(d.get_item('pri_subnet_cidr').to_s, options.priip.to_s)
          Whirly.stop

          Whirly.start status: 'Creating new deployment'
          m.create
          Whirly.stop
        end
      end
    end
  end
end
