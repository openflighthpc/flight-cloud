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
      c.option '--infrastructure NAME', String, 'Infrastructure identifier'
      c.option '--networkcidr CIDR', String, 'Primary network CIDR, e.g. 10.0.0.0/16'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--prvsubnetcidr NAME', String, 'Prv subnet CIDR'
      c.option '--mgtsubnetcidr NAME', String, 'Mgt subnet CIDR'
      c.action do |_args, options|
        if options.infrastructure.nil?
          options.infrastructure = ask("Infrastructure identifier?: ")
        end

        i = Cloudware::Infrastructure.new
        i.name = options.infrastructure.to_s
        unless i.check_infrastructure_exists == true
					abort("==> Infrastructure #{options.infrastructure.to_s} does not exist")
        end

				if options.provider.nil?
					options.provider = ask("Provider name?: ")
				end

				if options.networkcidr.nil?
					options.networkcidr = ask("Network CIDR?: ")
				end

				if options.prvsubnetcidr.nil?
					options.prvsubnetcidr = ask("Prv subnet CIDR?: ")
				end

				if options.mgtsubnetcidr.nil?
					options.mgtsubnetcidr = ask("Mgt subnet CIDR?: ")
				end

        i.provider = options.provider.to_s
				i.list.each do |ary|
					ary.each do |k|
							next if not k[0] == options.infrastructure.to_s
							if k[0] == options.infrastructure.to_s
                d = Cloudware::Domain.new
                d.name = options.infrastructure.to_s
                d.infrastructure = options.infrastructure.to_s
                d.networkcidr = options.networkcidr.to_s
                d.prvsubnetcidr = options.prvsubnetcidr.to_s
                d.mgtsubnetcidr = options.mgtsubnetcidr.to_s
                d.provider = options.provider.to_s
                d.create
							end
					end
				end
      end
    end

    command :'domain list' do |c|
      c.syntax = 'cloudware domain list [options]'
      c.description = 'List created domains'
      c.option '--provider NAME', String, 'Provider name'
      c.action do |_args, _options|
        rows = []
        d = Cloudware::Domain.new
        d.list.each do |l|
          rows.concat(l)
        end
        table = Terminal::Table.new headings: ['Infrastructure'.bold,
                                               'Network CIDR'.bold,
                                               'Prv Subnet CIDR'.bold,
                                               'Mgt Subnet CIDR'.bold,
                                               'Provider'.bold],
                                    rows: rows
        puts table
      end
    end

    command :'infrastructure create' do |c|
      c.syntax = 'cloudware infrastructure create [options]'
      c.description = 'Interact with infrastructure groups'
      c.option '--name NAME', String, 'Infrastructure identifier'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--region NAME', String, 'Region name to deploy into'
      c.action do |_args, options|
        if options.name.nil?
          options.name = ask("Infrastructure identity/name?: ", String)
        end
        if options.provider.nil?
          options.provider = ask("Provider name? [aws, azure, gcp]: ", String)
        end
        if options.region.nil?
          options.region = ask("Region ID?: ", String)
        end
        i = Cloudware::Infrastructure.new
        i.name = options.name.to_s
        i.provider = options.provider.to_s
        i.region = options.region.to_s
        i.create
      end
    end

    command :'infrastructure list' do |c|
      c.syntax = 'cloudware infrastructure list [options]'
      c.description = 'List infrastructure groups'
      c.option '--provider NAME', String, 'Provider name'
      c.action do |_args, options|
        rows = []
        i = Cloudware::Infrastructure.new
        i.provider = options.provider.to_s
        i.list.each do |l|
          rows.concat(l)
        end
        table = Terminal::Table.new headings: ['Identity'.bold,
                                               'Region'.bold,
                                               'Provider'.bold],
                                    rows: rows
        puts table
      end
    end

    command :'infrastructure destroy' do |c|
      c.syntax = 'cloudware infrastructure destroy [options]'
      c.description = 'Destroy infrastructure groups'
      c.option '--name NAME', String, 'Infrastructure identifier'
      c.option '--provider NAME', String, 'Provider name'
      c.action do |_args, options|
        i = Cloudware::Infrastructure.new
        i.name = options.name.to_s
        i.provider = options.provider.to_s
        i.destroy
      end
    end

    command :'machine create' do |c|
      c.syntax = 'cloudware machine create [options]'
      c.description = 'Create a new machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--infrastructure NAME', String, 'Infrastructure identifier'
      c.option '--type TYPE', String, 'Machine type to create'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--ipaddresstail INT', Integer, 'IP address tail'
      c.action do |_args, options|
        m = Cloudware::Machine.new
        m.name = options.name.to_s
        m.infrastructure = options.infrastructure.to_s
        m.type = options.type.to_s
        m.provider = options.provider.to_s
        m.ipaddresstail = options.ipaddresstail.to_s
        m.create
      end
    end
  end
end
