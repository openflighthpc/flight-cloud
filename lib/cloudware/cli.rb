# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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

require 'cloudware/command'
require 'cloudware/version'

require 'require_all'

# Require all the following paths
[
  'lib/cloudware/commands/concerns/**/*.rb',
  'lib/cloudware/commands/**/*.rb',
].each { |path| require_all File.join(Cloudware::Config.root_dir, path) }

module Cloudware
  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, Config.app_name
    program :version, Cloudware::VERSION
    program :description, 'Cloud orchestration tool'
    program :help_paging, false

    suppress_trace_class UserError

    # Display the help if there is no input arguments
    ARGV.push '--help' if ARGV.empty?

    def self.action(command, klass, method: :run!)
      command.action do |args, options|
        delayed_require
        hash = options.__hash__
        hash.delete(:trace)
        begin
          cmd = klass.new
          if hash.empty?
            cmd.public_send(method, *args)
          else
            cmd.public_send(method, *args, **hash)
          end
        rescue Exception => e
          Log.fatal(e.message)
          raise e
        end
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.hidden = true if command.name.split.length > 1
      command.sub_command_group = true
      command.syntax = <<~SYNTAX.squish
        #{program(:name)} #{command.name} #{args_str} [options]
      SYNTAX
    end

    def self.delayed_require
      require 'cloudware/models'
    end

    command 'cluster' do |c|
      cli_syntax(c)
      c.summary = 'Manage the current cluster selection'
    end

    command 'cluster switch' do |c|
      cli_syntax(c, 'CLUSTER')
      c.summary = 'Change the current cluster to CLUSTER'
      action(c, Commands::ClusterCmd, method: :switch)
    end

    cluster_templates = proc do |c|
      cli_syntax(c)
      c.summary = 'Lists the available templates for the cluster'
      c.description = <<~DESC
        Lists the templates for a particular cluster. These templates
        can be used directly with the `deploy` command.

        By default the template name is not required if it can be
        unambiguously determined from the directory name. Use the
        verbose option to see the full template paths
      DESC
      c.option '--verbose', 'Show the shorthand mappigns'
      action(c, Commands::Deploy, method: :list_templates)
    end

    command 'cluster templates', &cluster_templates
    command 'list templates', &cluster_templates

    command 'deploy' do |c|
      cli_syntax(c, 'NAME TEMPLATE')
      c.summary = 'Deploy new resource(s) define by a template'
      c.description = <<-DESC.strip_heredoc
        Deploy new resource(s) from the specified TEMPLATE. The TEMPLATE can
        either be a cluster template or an absolute path.

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
      c.summary = 'Destroy a deployment and related resouces'
      c.description = <<~DESC
        Removes the deployment NAME and instructs the cloud provider to destroy
        the related resources.
      DESC
      c.option '--force', 'Force delete the deployment from the context'
      action(c, Commands::Destroy)
    end

    command 'import' do |c|
      cli_syntax(c, 'ZIP_PATH')
      c.summary = 'Add templates to the cluster'
      c.description = <<~DESC.split("\n\n").map(&:squish).join("\n")
        Imports the '#{Config.provider}' templates into the internal cache. The
        ZIP_PATH must be a zip file containing an '#{Config.provider}'
        directory.\n\n

        These templates can then be used to deploy resource using:\n
        #{Config.app_name} deploy foo template
      DESC
      action(c, Commands::Import)
    end

    command 'list' do |c|
      cli_syntax(c)
      c.summary = 'List the deployed cloud resources'
    end

    list_clusters_proc = proc do |c|
      cli_syntax(c)
      c.summary = 'Show the current and available clusters'
      c.description = <<~DESC
        Shows a list of clusters that have been previously deployed to
      DESC
      action(c, Commands::ClusterCmd, method: :list)
    end

    command('list clusters', &list_clusters_proc)
    command('cluster list', &list_clusters_proc)

    command 'list deployments' do |c|
      cli_syntax(c)
      c.description = 'List all the previous deployed templates'
      c.option '-v', '--verbose', 'Show full error messages'
      action(c, Commands::Lists::Deployment)
    end

    command 'list machines' do |c|
      cli_syntax(c)
      c.summary = 'List all the previous deployed machines'
      c.description = <<~DESC
        List the machines created within a previous deployment. This command
        does not poll the provider for any information.

        Instead it list the deployment outputs which follow the machine tag
        format: `<machine-name>TAG<key>`
      DESC
      action(c, Commands::Lists::Machine)
    end

    command 'power' do |c|
      cli_syntax(c)
      c.description = 'Start or stop machine and check their power status'
    end

    def self.shared_power_attr(c)
      action = c.name.split.last
      cli_attr = 'IDENTIFIER'
      cli_syntax(c, cli_attr)
      c.option '-g', '--group', <<~DESC
        Preform the '#{action}' action on machine in group '#{cli_attr}'
      DESC
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
