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

          options.prvip = ask('Prv subnet IP: ') if options.prvip.nil?
          m.prvip = options.prvip.to_s

          options.mgtip = ask('Mgt subnet IP: ') if options.mgtip.nil?
          m.mgtip = options.mgtip.to_s

          run_whirly('Verifying domain exists') do
            raise("Domain #{options.domain} does not exist") unless m.valid_domain?
          end

          run_whirly('Checking machine name is valid') do
            raise("Machine name #{options.name} is not a valid machine name") unless m.validate_name?
            Whirly.status = 'Verifying prv IP address'
            raise("Invalid prv IP address #{options.prvip} in subnet #{d.get_item('prv_subnet_cidr')}") unless m.valid_ip?(d.get_item('prv_subnet_cidr').to_s, options.prvip.to_s)
            Whirly.status = 'Verifying mgt IP address'
            raise("Invalid mgt IP address #{options.mgtip} in subnet #{d.get_item('mgt_subnet_cidr')}") unless m.valid_ip?(d.get_item('mgt_subnet_cidr').to_s, options.mgtip.to_s)
          end

          run_whirly('Creating new deployment') do
            m.create
          end
        end
      end
    end
  end
end
