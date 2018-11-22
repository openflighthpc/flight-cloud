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

require 'require_all'
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
      c.option '--parent NAME', String,
               'Subsitute the parents deployment output into the template'
      action(c, Commands::Deploy)
    end

    command 'destroy' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Destroy'
      action(c, Commands::Destroy)
    end

    command 'power' do |c|
      cli_syntax(c)
      c.description = 'Power'
      c.sub_command_group = true
    end

    def self.shared_power_attr(c)
      cli_syntax(c, 'MACHINE')
      c.option '-d', '--deployment DEPLOYMENT', String,
               'The deployment the machine was created in'
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
  end
end
