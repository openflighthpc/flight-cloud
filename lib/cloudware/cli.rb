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
require 'whirly'
require 'exceptions'
require 'command'
require 'models/application'

require 'require_all'
require_all 'lib/cloudware/commands/concerns/**/*.rb'
require_all 'lib/cloudware/commands/**/*.rb'
require_all 'lib/cloudware/models/**/*.rb'

require 'providers'

module Cloudware
  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, 'flightconnector'
    program :version, '0.0.1'
    program :description, 'Cloud orchestration tool'

    suppress_trace_class UserError

    # Display the help if there is no input arguments
    ARGV.push '--help' if ARGV.empty?

    def self.action(command, klass)
      command.action do |args, options|
        klass.new(args, options).run!
      end
    end

    def self.cli_syntax(command, args_str = '')
      s = "flightconnector #{command.name} #{args_str} [options]".squish
      command.syntax = s
    end

    def self.provider_and_region_options(command)
      command.option '-p', '--provider NAME', String,
                     { default: Cloudware.config.default.provider },
                     'Cloud service provider name'
      command.option '-r', '--region NAME', String,
                     { default: Cloudware.config.default.region },
                     'Provider region to create domain in'
    end

    command :domain do |c|
      c.syntax = 'flightconnector domain [options]'
      c.description = 'Manage a domain'
      c.sub_command_group = true
    end

    command :'domain create' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Create a new domain'
      provider_and_region_options(c)
      c.option '--networkcidr CIDR',
               String, { default: '10.0.0.0/16' },
               <<~SUMMARY.squish
                 Entire network CIDR. The pri subnet must be
                 within this range'
               SUMMARY
      c.option '--prisubnetcidr NAME',
               String, { default: '10.0.1.0/24' },
               'Pri subnet CIDR'
      c.option '--cluster-index INDEX', String,
               'Cluster index to be passed into the template'
      c.option '-t', '--template TEMPLATE',
               String, { default: 'domain' },
               'Provider template to build the domain from'
      c.hidden = true
      action(c, Commands::Domain::Create)
    end

    command :'domain list' do |c|
      c.syntax = 'flightconnector domain list [options]'
      c.description = 'List created domains'
      provider_and_region_options(c)
      c.option '-a', '--all-regions', <<-OPTION.squish
        List domains in all the regions. This option overrides the region
        input
      OPTION
      c.hidden = true
      action(c, Commands::Domain::List)
    end

    command :'domain destroy' do |c|
      c.syntax = 'flightconnector domain destroy NAME [options]'
      c.description = 'Destroy a machine'
      provider_and_region_options(c)
      c.hidden = true
      action(c, Commands::Domain::Destroy)
    end

    command :machine do |c|
      c.syntax = 'flightconnector machine [options]'
      c.description = 'Manage a cloud machine'
      c.sub_command_group = true
    end

    command :'machine create' do |c|
      c.syntax = 'flightconnector machine create NAME [options]'
      c.description = 'Create a new machine'
      provider_and_region_options(c)
      c.option '-d', '--domain NAME', String, 'Domain name'
      c.option '--role NAME', String,
               'Machine role to inherit (master or slave)'
      c.option '--priip ADDR', String,
               'Pri subnet IP address'
      c.option '--type NAME', String,
               { default: 'small' },
               'Flavour of machine type to deploy, e.g. medium'
      c.option '--flavour NAME', String,
               { default: 'compute' },
               'Type of machine to deploy, e.g. gpu'

      c.hidden = true
      action(c, Commands::Machine::Create)
    end

    command :'machine list' do |c|
      c.syntax = 'flightconnector machine list'
      c.option '--provider NAME', String, 'Cloud provider to show machines for'
      c.description = 'List available machines'
      provider_and_region_options(c)
      c.hidden = true
      action(c, Commands::Machine::List)
    end

    command :'machine info' do |c|
      c.syntax = 'flightconnector machine info NAME [options]'
      c.description = 'List detailed information about a given machine'
      provider_and_region_options(c)
      c.option '-d', '--domain NAME', String,
               'Domain the machine belongs to'
      c.hidden = true
      action(c, Commands::Machine::Info)
    end

    command :'machine destroy' do |c|
      c.syntax = 'flightconnector machine destroy NAME [options]'
      c.description = 'Destroy a machine'
      provider_and_region_options(c)
      c.option '-d', '--domain NAME', String,
               'Domain the machine belongs to'
      c.hidden = true
      action(c, Commands::Machine::Destroy)
    end

    command :'machine power status' do |c|
      c.syntax = 'flightconnector machine power status NAME [options]'
      c.description = 'Check the power status of a machine'
      provider_and_region_options(c)
      c.option '-d', '--domain NAME', String,
               'Domain the machine belongs to'
      c.hidden = true
      action(c, Commands::Machine::Power::Status)
    end

    command :'machine power on' do |c|
      c.syntax = 'flightconnector machine power on [options]'
      c.description = 'Turn a machine on'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      c.hidden = true
      action(c, Commands::Machine::Power::On)
    end

    command :'machine power off' do |c|
      c.syntax = 'flightconnector machine power off [options]'
      c.description = 'Turn a machine off'
      c.option '--name NAME', String, 'Machine name'
      c.option '--domain NAME', String, 'Domain identifier'
      c.hidden = true
      action(c, Commands::Machine::Power::Off)
    end

    command :'machine rebuild' do |c|
      c.syntax = 'flightconnector machine rebuild NAME [options]'
      c.description = 'Rebuild a machine'
      provider_and_region_options(c)
      c.option '-d', '--domain NAME', String,
               'Domain the machine belongs to'
      c.hidden = true
      action(c, Commands::Machine::Rebuild)
    end
  end
end
