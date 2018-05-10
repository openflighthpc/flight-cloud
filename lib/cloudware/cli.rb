# frozen_string_literal: true

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
require 'exceptions'
require 'command'

require 'require_all'
require_all 'lib/cloudware/commands/**/*.rb'

module Cloudware
  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, 'cloudware'
    program :version, '0.0.1'
    program :description, 'Cloud orchestration tool'

    def self.action(command, klass)
      command.action do |args, options|
        klass.new(args, options).run!
      end
    end

    command :'domain create' do |c|
      c.syntax = 'cloudware domain create [options]'
      c.description = 'Create a new domain'
      c.option '--name NAME', String, 'Name of cloud domain'
      c.option '--networkcidr CIDR', String, 'Entire network CIDR, e.g. 10.0.0.0/16. The prv and mgt subnet must be within this range'
      c.option '--provider NAME', String, 'Cloud service provider name'
      c.option '--prvsubnetcidr NAME', String, 'Prv subnet CIDR'
      c.option '--mgtsubnetcidr NAME', String, 'Mgt subnet CIDR'
      c.option '--region NAME', String, 'Provider region to create domain in'
      action(c, Commands::Domain::Create)
    end

    command :'domain list' do |c|
      c.syntax = 'cloudware domain list [options]'
      c.description = 'List created domains'
      c.option '--provider NAME', String, 'Cloud provider name to filter by'
      c.option '--region NAME', String, 'Cloud provider region to filter by'
      action(c, Commands::Domain::List)
    end

    command :'domain destroy' do |c|
      c.syntax = 'cloudware domain destroy [options]'
      c.description = 'Destroy a machine'
      c.option '--name NAME', String, 'Domain name'
      c.action do |_args, options|
        begin
          d = Cloudware::Domain.new

          options.name = ask('Domain name: ') if options.name.nil?
          d.name = options.name.to_s

          Whirly.start spinner: 'dots2', status: 'Checking domain exists'.bold, stop: '[OK]'.green
          raise("Domain name #{options.name} does not exist") unless d.exists?
          Whirly.stop

          Whirly.start spinner: 'dots2', status: "Destroying domain #{options.name}".bold, stop: '[OK]'.green
          d.destroy
          Whirly.stop
        rescue RuntimeError => error
          Cloudware.log.error("Failed destroying domain: #{error.message}")
          raise error.message
        end
      end
    end

    command :'machine create' do |c|
      c.syntax = 'cloudware machine create [options]'
      c.description = 'Create a new machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain name'
      c.option '--role NAME', String, 'Machine role to inherit (master or slave)'
      c.option '--prvip ADDR', String, 'Prv subnet IP address'
      c.option '--mgtip ADDR', String, 'Mgt subnet IP address'
      c.option '--type NAME', String, 'Flavour of machine type to deploy, e.g. medium'
      c.option '--flavour NAME', String, 'Type of machine to deploy, e.g. gpu'
      action(c, Commands::Machine::Create)
    end

    command :'machine list' do |c|
      c.syntax = 'cloudware machine list'
      c.option '--provider NAME', String, 'Cloud provider to show machines for'
      c.description = 'List available machines'
      action(c, Commands::Machine::List)
    end

    command :'machine info' do |c|
      c.syntax = 'cloudware machine info [options]'
      c.description = 'List detailed information about a given machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain name'
      c.option '--output TYPE', String, 'Output type [table]. Default: table'
      action(c, Commands::Machine::Info)
    end

    command :'machine destroy' do |c|
      c.syntax = 'cloudware machine destroy [options]'
      c.description = 'Destroy a machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      action(c, Commands::Machine::Destroy)
    end

    command :'machine power status' do |c|
      c.syntax = 'cloudware machine power status [options]'
      c.description = 'Check the power status of a machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      action(c, Commands::Machine::Power::Status)
    end

    command :'machine power on' do |c|
      c.syntax = 'cloudware machine power on [options]'
      c.description = 'Turn a machine on'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      action(c, Commands::Machine::Power::On)
    end

    command :'machine power off' do |c|
      c.syntax = 'cloudware machine power off [options]'
      c.description = 'Turn a machine off'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      action(c, Commands::Machine::Power::Off)
    end

    command :'machine rebuild' do |c|
      c.syntax = 'cloudware machine rebuild [options]'
      c.description = 'Rebuild a machine'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      action(c, Commands::Machine::Rebuild)
    end
  end
end
