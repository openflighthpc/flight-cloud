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
    global_option('--region', "Specify a provider's region")

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
      c.summary = 'Deploy new resource(s) from template'
      c.description = <<-DESC.strip_heredoc
        Deploy new resource(s) from the specified TEMPLATE. The templates can
        be stored within the template directories below. The file extension is
        automatically inferred depending on the provider.
          => #{Config.content_path}/templates/<provider>

        Alternatively the absolute path (including extension) to the template
        can be used.

        The deployment will be given the NAME lable which will also dictate the
        name given to the provider. There maybe minor variations depending on
        the platform.

        The templates also support basic rendering of parameters from the
        command line. This is intended to provide minor tweaks to the templates
        (e.g. IPs or names). Major difference should use separate templates.

        The key value pairs to be rendered are given by the `--param` option.
        The renderer will replace occurrences of `%REPLACE_KEY%` in the template
        with the `IDENTIFIER`. By default this is a simple string substitution.

        It is possible to reference keys within previous deployments using the
        `*` prefix. This will cause `*IDENTIFIER` to be interpreted as a
        deployment name. In this case, the deployment result corresponding with
        `OUTPUT_KEY` is used in the sustitution. If `OUTPUT_KEY` is missing,
        then it is assumed to be the same as `REPLACE_KEY`.
      DESC
      c.option '-p', '--params \'<REPLACE_KEY=*IDENTIFIER[.OUTPUT_KEY] >...\'',
               String, 'A space separate list of keys to replace'
      action(c, Commands::Deploy)
    end

    command 'destroy' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Destroy the deployment and related resources'
      action(c, Commands::Destroy)
    end

    command 'info' do |c|
      cli_syntax(c)
      c.description = 'Information related subcommands'
      c.sub_command_group = true
    end

    command 'info machine' do |c|
      cli_syntax(c, 'NAME')
      c.description = 'Display the tag information about a machine'
      c.option '-d', '--deployment DEPLOYMENT', String,
               'The deployment the machine was created in'
      c.hidden = true
      action(c, Commands::Infos::Machine)
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
