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
require 'whirly'
require 'exceptions'
require 'command'

require 'require_all'

require_all 'lib/cloudware/models/concerns/**/*.rb'
require_all 'lib/cloudware/models/**/*.rb'

require_all 'lib/cloudware/commands/concerns/**/*.rb'
require_all 'lib/cloudware/commands/**/*.rb'

module Cloudware
  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, 'flightconnector'
    program :version, '0.0.1'
    program :description, 'Cloud orchestration tool'

    global_option('--debug', 'Enables the development mode')

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

    command 'deploy' do |c|
      cli_syntax(c, 'TEMPLATE NAME')
      c.description = 'Deploy'
      c.option '-p', "--params '<REPLACE_KEY=DEPLOYMENT[.OUTPUT_KEY] >...'",
               String, 'A space separate list of keys to replace'
      action(c, Commands::Deploy)
    end

    command 'destroy' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Destroy'
      action(c, Commands::Destroy)
    end

    command 'info' do |c|
      cli_syntax(c)
      c.description = 'Info'
      c.sub_command_group = true
    end

    command 'info machine' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Machine Info'
      c.option '-d', '--deployment DEPLOYMENT', String,
               'The deployment the machine was created in'
      c.hidden = true
      action(c, Commands::Infos::Machine)
    end

    command 'info domain' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Domain Info'
      c.option '-d', '--deployment DEPLOYMENT', String,
               'The deployment the machine was created in'
      c.hidden = true
      action(c, Commands::Infos::Domain)
    end

    command 'list' do |c|
      cli_syntax(c)
      c.description = 'list'
      c.sub_command_group = true
    end

    command 'list machines' do |c|
      cli_syntax(c)
      c.description = 'List all the machines'
      c.hidden = true
      action(c, Commands::Lists::Machine)
    end

    command 'list domains' do |c|
      cli_syntax(c)
      c.description = 'List all the domains'
      c.hidden = true
      action(c, Commands::Lists::Domain)
    end

    command 'power' do |c|
      cli_syntax(c)
      c.description = 'Power'
      c.sub_command_group = true
    end

    def self.shared_power_attr(c)
      cli_attr = 'IDENTIFIER'
      cli_syntax(c, cli_attr)
      c.option '-d', '--deployment DEPLOYMENT', String,
               'The deployment the machine was created in'
      c.option '-g', '--group',
               "Preform the action over the group specified by #{cli_attr}"
      c.hidden = true
    end

    command 'power status' do |c|
      shared_power_attr(c)
      c.description = 'Check the power state of a machine'
      action(c, Commands::Powers::Status)
    end

    command 'power off' do |c|
      shared_power_attr(c)
      c.description = 'Turn the machine off'
      action(c, Commands::Powers::Off)
    end

    command 'power on' do |c|
      shared_power_attr(c)
      c.description = 'Turn the machine on'
      action(c, Commands::Powers::On)
    end
  end
end
