#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================
require 'commander'
require 'terminal-table'
require 'colorize'
require 'whirly'

module Cloudware
  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, 'cloudware'
    program :version, '0.0.1'
    program :description, 'Cloud orchestration tool'

    command :'domain create' do |c|
      c.syntax = 'cloudware domain create [options]'
      c.description = 'Create a new domain'
      c.option '--name NAME', String, 'Domain name'
      c.option '--networkcidr CIDR', String, 'Primary network CIDR, e.g. 10.0.0.0/16'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--prvsubnetcidr NAME', String, 'Prv subnet CIDR'
      c.option '--mgtsubnetcidr NAME', String, 'Mgt subnet CIDR'
      c.option '--region NAME', String, 'Provider region to create domain in'
      c.action do |_args, options|
        d = Cloudware::Domain.new

        options.name = ask('Domain identifier: ') if options.name.nil?
        d.name = options.name.to_s

        options.provider = choose('Provider name?', :aws, :azure, :gcp) if options.provider.nil?
        d.provider = options.provider.to_s

        options.region = ask('Provider region: ') if options.region.nil?
        d.region = options.region.to_s

        options.networkcidr = ask('Network CIDR: ') if options.networkcidr.nil?
        d.networkcidr = options.networkcidr.to_s

        options.prvsubnetcidr = ask('Prv subnet CIDR: ') if options.prvsubnetcidr.nil?
        d.prvsubnetcidr = options.prvsubnetcidr.to_s

        options.mgtsubnetcidr = ask('Mgt subnet CIDR: ') if options.mgtsubnetcidr.nil?
        d.mgtsubnetcidr = options.mgtsubnetcidr.to_s

        Whirly.start spinner: 'dots2', status: 'Verifying provider is valid'.bold, stop: '[OK]'.green
        raise("Provider #{options.provider} does not exist") unless d.valid_provider?
        Whirly.status = 'Verifying network CIDR is valid'.bold
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
        Whirly.stop

        Whirly.start spinner: 'dots2', status: 'Creating new deployment'.bold, stop: '[OK]'.green
        d.create
        Whirly.stop
      end
    end

    command :'domain list' do |c|
      c.syntax = 'cloudware domain list [options]'
      c.description = 'List created domains'
      c.option '--provider NAME', String, 'Provider name to filter by'
      c.option '--region NAME', String, 'Provider region to filter by'
      c.action do |_args, options|
        d = Cloudware::Domain.new
        d.provider = options.provider.to_s unless options.provider.nil?
        d.region = options.region.to_s unless options.region.nil?
        d.name = options.name.to_s unless options.name.nil?
        r = []
        Whirly.start spinner: 'dots2', status: 'Fetching available domains'.bold, stop: '[OK]'.green
        raise('No available domains') if d.list.empty?
        Whirly.stop
        d.list.each do |k, v|
          r << [k, v[:network_cidr], v[:prv_subnet_cidr], v[:mgt_subnet_cidr], v[:provider], v[:region]]
        end
        table = Terminal::Table.new headings: ['Domain name'.bold,
                                               'Network CIDR'.bold,
                                               'Prv Subnet CIDR'.bold,
                                               'Mgt Subnet CIDR'.bold,
                                               'Provider'.bold,
                                               'Region'.bold],
                                    rows: r
        puts table
      end
    end

    command :'domain destroy' do |c|
      c.syntax = 'cloudware domain destroy [options]'
      c.description = 'Destroy a machine'
      c.option '--name NAME', String, 'Domain name'
      c.action do |_args, options|
        d = Cloudware::Domain.new

        options.name = ask('Domain name: ') if options.name.nil?
        d.name = options.name.to_s

        Whirly.start spinner: 'dots2', status: 'Checking domain exists'.bold, stop: '[OK]'.green
        raise("Domain name #{options.name} does not exist") unless d.exists?
        Whirly.stop

        Whirly.start spinner: 'dots2', status: "Destroying domain #{options.name}".bold, stop: '[OK]'.green
        d.destroy
        Whirly.stop
      end
    end

    command :'machine create' do |c|
      c.syntax = 'cloudware machine create [options]'
      c.description = 'Create a new machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain name'
      c.option '--role NAME', String, 'Machine role to inherit'
      c.option '--prvip ADDR', String, 'Prv subnet IP address'
      c.option '--mgtip ADDR', String, 'Mgt subnet IP address'
      c.option '--type NAME', String, 'Machine type to deploy'
      c.option '--flavour NAME', String, 'Machine flavour'
      c.action do |_args, options|
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

        Whirly.start spinner: 'dots2', status: 'Verifying domain exists'.bold, stop: '[OK]'.green
        raise("Domain #{options.domain} does not exist") unless m.valid_domain?
        Whirly.stop

        Whirly.start spinner: 'dots2', status: 'Checking machine name is valid'.bold, stop: '[OK]'.green
        raise("Machine name #{options.name} is not a valid machine name") unless m.validate_name?
        Whirly.status = 'Verifying prv IP address'.bold
        raise("Invalid prv IP address #{options.prvip} in subnet #{d.get_item('prv_subnet_cidr')}") unless m.valid_ip?(d.get_item('prv_subnet_cidr').to_s, options.prvip.to_s)
        Whirly.status = 'Verifying mgt IP address'.bold
        raise("Invalid mgt IP address #{options.mgtip} in subnet #{d.get_item('mgt_subnet_cidr')}") unless m.valid_ip?(d.get_item('mgt_subnet_cidr').to_s, options.mgtip.to_s)
        Whirly.stop

        Whirly.start spinner: 'dots2', status: 'Creating new deployment'.bold, stop: '[OK]'.green
        m.create
        Whirly.stop
      end
    end

    command :'machine list' do |c|
      c.syntax = 'cloudware machine list'
      c.option '--domain NAME', String, 'Filter results by domain name'
      c.description = 'List available machines'
      c.action do |_args, options|
        m = Cloudware::Machine.new
        r = []
        Whirly.start spinner: 'dots2', status: 'Fetching available machines'.bold, stop: '[OK]'.green
        raise('No available machines') if m.list.nil?
        Whirly.stop
        m.list.each do |_k, v|
          if options.domain
            if v[:domain] == options.domain
              r << [v[:name], v[:domain], v[:role], v[:prv_ip], v[:mgt_ip], v[:type]]
            end
          else
            r << [v[:name], v[:domain], v[:role], v[:prv_ip], v[:mgt_ip], v[:type]]
          end
        end
        table = Terminal::Table.new headings: ['Name'.bold,
                                               'Domain'.bold,
                                               'Role'.bold,
                                               'Prv IP address'.bold,
                                               'Mgt IP address'.bold,
                                               'Type'.bold],
                                    rows: r
        puts table
      end
    end

    command :'machine info' do |c|
      c.syntax = 'cloudware machine info [options]'
      c.description = 'List detailed information about a given machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain name'
      c.option '--output TYPE', String, 'Output type [json, table]. Default: table'
      c.action do |_args, options|
        options.default output: 'table'
        m = Cloudware::Machine.new
        m.name = options.name.to_s
        m.domain = options.domain.to_s

        case options.output.to_s
        when 'table'
          table = Terminal::Table.new do |t|
            Whirly.start spinner: 'dots2', status: 'Fetching machine info'.bold, stop: '[OK]'.green
            t.add_row ['Machine name'.bold, m.name]
            t.add_row ['Domain name'.bold, m.get_item('domain')]
            t.add_row ['Machine role'.bold, m.get_item('role')]
            t.add_row ['Prv subnet IP'.bold, m.get_item('prv_ip')]
            t.add_row ['Mgt subnet IP'.bold, m.get_item('mgt_ip')]
            t.add_row ['External IP'.bold, m.get_item('ext_ip')]
            t.add_row ['Machine state'.bold, m.get_item('state')]
            t.add_row ['Machine type'.bold, m.get_item('type')]
            t.add_row ['Machine flavour'.bold, m.get_item('flavour')]
            t.add_row ['Provider'.bold, m.get_item('provider')]
            Whirly.stop
            t.style = { all_separators: true }
          end
          puts table
        end
      end
    end

    command :'machine destroy' do |c|
      c.syntax = 'cloudware machine destroy [options]'
      c.description = 'Destroy a machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      c.action do |_args, options|
        m = Cloudware::Machine.new

        options.name = ask('Machine name: ') if options.name.nil?
        m.name = options.name.to_s

        options.domain = ask('Domain identifier: ') if options.domain.nil?
        m.domain = options.domain.to_s

        Whirly.start spinner: 'dots2', status: 'Checking machine exists'.bold, stop: '[OK]'.green
        raise('Machine does not exist') unless m.exists?
        Whirly.stop

        Whirly.start spinner: 'dots2', status: "Destroying #{options.name} in domain #{options.domain}".bold, stop: '[OK]'.green
        m.destroy
        Whirly.stop
      end
    end
  end
end
