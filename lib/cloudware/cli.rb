# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

require 'commander'
require 'cloudware/exceptions'

require 'cloudware/command'
require 'cloudware/version'

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

    program :name, File.basename($PROGRAM_NAME)
    program :version, Cloudware::VERSION
    program :description, 'Cloud orchestration tool'

    global_option('--region REGION', 'Specify cloud platform region')

    suppress_trace_class UserError

    # Display the help if there is no input arguments
    ARGV.push '--help' if ARGV.empty?

    def self.action(command, klass)
      command.action do |args, options|
        klass.new(args, options).run!
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.syntax = <<~SYNTAX.squish
        #{program(:name)} #{command.name} #{args_str} [options]
      SYNTAX
    end

    command 'deploy' do |c|
      cli_syntax(c, 'NAME TEMPLATE')
      c.summary = 'Deploy new resource(s) from template'
      c.description = <<-DESC.strip_heredoc
        Deploy new resource(s) from the specified TEMPLATE. This should
        specifiy the absolute path (including extension) to the template.

        The deployment will be given the NAME label and logged locally. The name
        used by the provider will be based off this with minor variations.

        The templates also support basic rendering of parameters from the
        command line. This is intended to provide minor tweaks to the templates
        (e.g. IPs or names). Major difference should use separate templates.
      DESC
      c.option '-p', '--params \'<REPLACE_KEY=*IDENTIFIER[.OUTPUT_KEY] >...\'',
               String, 'A space separated list of keys to be replaced'
      action(c, Commands::Deploy)
    end

    command 'destroy' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Destroy the deployment and related resources'
      action(c, Commands::Destroy)
    end

    command 'list' do |c|
      cli_syntax(c)
      c.description = 'List related subcommands'
      c.sub_command_group = true
    end

    command 'list deployments' do |c|
      cli_syntax(c)
      c.description = 'List all the deployments'
      c.hidden = true
      action(c, Commands::Lists::Deployment)
    end

    command 'list machines' do |c|
      cli_syntax(c)
      c.description = 'List all the machines'
      c.hidden = true
      action(c, Commands::Lists::Machine)
    end

    command 'power' do |c|
      cli_syntax(c)
      c.description = 'Power related commands'
      c.sub_command_group = true
    end

    def self.shared_power_attr(c)
      cli_attr = 'IDENTIFIER'
      cli_syntax(c, cli_attr)
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
