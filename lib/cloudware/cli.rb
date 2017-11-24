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

        options.provider = ask('Provider name: ') if options.provider.nil?
        d.provider = options.provider.to_s

        options.region = ask('Provider region: ') if options.region.nil?
        d.region = options.region.to_s

        options.networkcidr = ask('Network CIDR: ') if options.networkcidr.nil?
        d.networkcidr = options.networkcidr.to_s

        options.prvsubnetcidr = ask('Prv subnet CIDR: ') if options.prvsubnetcidr.nil?
        d.prvsubnetcidr = options.prvsubnetcidr.to_s

        options.mgtsubnetcidr = ask('Mgt subnet CIDR: ') if options.mgtsubnetcidr.nil?
        d.mgtsubnetcidr = options.mgtsubnetcidr.to_s

        puts 'Starting deployment. This may take a while..'.bold
        d.create
        puts 'Deployment complete'.bold.green
      end
    end

    command :'domain list' do |c|
      c.syntax = 'cloudware domain list [options]'
      c.description = 'List created domains'
      c.option '--provider NAME', String, 'Provider name'
      c.action do |_args, _options|
        d = Cloudware::Domain.new
        r = []
        abort('No available domains') if d.list.empty?
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
        m = Cloudware::Domain.new

        options.name = ask('Domain name: ') if options.name.nil?
        m.name = options.name.to_s

        puts "Destroying domain #{options.name}. This may take a while..".bold
        m.destroy
        puts 'Operation complete'.green.bold
      end
    end

    command :'machine create' do |c|
      c.syntax = 'cloudware machine create [options]'
      c.description = 'Create a new machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain name'
      c.option '--type TYPE', String, 'Machine type to create'
      c.option '--prvsubnetip ADDR', String, 'Prv subnet IP address'
      c.option '--mgtsubnetip ADDR', String, 'Mgt subnet IP address'
      c.option '--size NAME', String, 'Provider specific instance size'
      c.action do |_args, options|
        m = Cloudware::Machine.new

        options.name = ask('Machine name: ') if options.name.nil?
        m.name = options.name.to_s

        options.domain = ask('Domain identifier: ') if options.domain.nil?
        m.domain = options.domain.to_s

        options.type = ask('Machine type [master,slave]: ') if options.type.nil?
        m.type = options.type.to_s

        options.prvsubnetip = ask('Prv subnet IP: ') if options.prvsubnetip.nil?
        m.prvsubnetip = options.prvsubnetip.to_s

        options.mgtsubnetip = ask('Mgt subnet IP: ') if options.mgtsubnetip.nil?
        m.mgtsubnetip = options.mgtsubnetip.to_s

        options.size = ask('Machine size: ') if options.size.nil?
        m.size = options.size.to_s

        puts "Creating #{options.name} in domain #{options.domain}".bold
        puts 'This may take a while..'
        m.create
        puts 'Operation complete'.green.bold
      end
    end

    command :'machine list' do |c|
      c.syntax = 'cloudware machine list'
      c.description = 'List available machines'
      c.action do |_args, _options|
        m = Cloudware::Machine.new
        r = []
        m.list.each do |k, v|
          r << [k, v[:cloudware_domain], v[:cloudware_machine_type], v[:prv_ip], v[:mgt_ip], v[:size]]
        end
        table = Terminal::Table.new headings: ['Machine name'.bold,
                                               'Domain name'.bold,
                                               'Machine type'.bold,
                                               'Prv IP address'.bold,
                                               'Mgt IP address'.bold,
                                               'Size'.bold],
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
            t.add_row ['Machine name'.bold, m.name]
            t.add_row ['Domain name'.bold, m.get_item('cloudware_domain')]
            t.add_row ['Machine type'.bold, m.get_item('cloudware_machine_type')]
            t.add_row ['Prv subnet IP'.bold, m.get_item('prv_ip')]
            t.add_row ['Mgt subnet IP'.bold, m.get_item('mgt_ip')]
            t.add_row ['External IP'.bold, m.get_item('ext_ip')]
            t.add_row ['Instance state'.bold, m.get_item('state')]
            t.add_row ['Instance size'.bold, m.get_item('size')]
            t.add_row ['Provider'.bold, m.get_item('provider')]
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

        puts "Destroying #{options.name} in domain #{options.domain}"
        puts 'This may take a while...'
        m.destroy
        puts 'Operation complete'
      end
    end
  end
end
