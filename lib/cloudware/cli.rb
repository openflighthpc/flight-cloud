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
require 'cloudware/log'
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

    silent_trace!

    def self.run!
      # Display the help if there is no input arguments
      ARGV.push '--help' if ARGV.empty?
      Log.info "Run (CLI): #{ARGV.join(' ')}"
      super
    end

    def self.action(command, klass, method: :run!)
      command.action do |args, options|
        hash = options.__hash__
        hash.delete(:trace)
        begin
          begin
            cmd = klass.new
            if hash.empty?
              cmd.public_send(method, *args)
            else
              cmd.public_send(method, *args, **hash)
            end
          rescue Interrupt
            raise RuntimeError, 'Received Interrupt!'
          end
        rescue StandardError => e
          Log.fatal(e.message)
          raise e
        end
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.hidden = true if command.name.split.length > 1
      command.syntax = <<~SYNTAX.squish
        #{program(:name)} #{command.name} #{args_str} [options]
      SYNTAX
    end

    command 'cluster' do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = 'Manage the current cluster selection'
    end

    command 'cluster init' do |c|
      cli_syntax(c, 'CLUSTER')
      c.summary = 'Create a new cluster'
      c.description = <<~DESC
        Create a new cluster that can be identified by CLUSTER. The cluster
        must not already exist. Use the `--import` option to import templates
        into your new cluster. See `#{Config.app_name} import` for further
        details.
      DESC
      c.option '--import PATH', String, 'Specify a zip file to import'
      action(c, Commands::ClusterCommand, method: :init)
    end

    command 'cluster switch' do |c|
      cli_syntax(c, 'CLUSTER')
      c.summary = 'Change the current cluster to CLUSTER'
      action(c, Commands::ClusterCommand, method: :switch)
    end

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
      c.summary = 'Stop a running deployment'
      action(c, Commands::Destroy)
    end

    command 'delete' do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Remove the deployments configuration file'
      c.description = <<~DESC
        Deletes the confiuration file for the deployment NAME. This action
        will error if the resources are currently running. The resources can
        be stop using the 'destroy' command.

        The configuration of a currently running deployment can be deleted
        using the '--force' flag. This will not destroy the remote resources
      DESC
      c.option '--force', 'Delete the deployment regardless if running'
      action(c, Commands::Destroy, method: :delete)
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
      c.sub_command_group = true
      c.summary = 'List the deployed cloud resources'
    end

    list_clusters_proc = proc do |c|
      cli_syntax(c)
      c.summary = 'Show the current and available clusters'
      c.description = <<~DESC
        Shows a list of clusters that have been previously deployed to
      DESC
      action(c, Commands::ClusterCommand, method: :list)
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

    command 'list templates' do |c|
      cli_syntax(c)
      c.summary = 'Lists the available templates for the cluster'
      c.description = <<~DESC
        Lists the templates for a particular cluster. These templates
        can be used directly with the `deploy` command.

        By default the template name is not required if it can be
        unambiguously determined from the directory name. Use the
        verbose option to see the full template paths
      DESC
      c.option '--verbose', 'Show the shorthand mappings'
      action(c, Commands::Deploy, method: :list_templates)
    end

    command 'power' do |c|
      cli_syntax(c)
      c.sub_command_group = true
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

    command 'render' do |c|
      cli_syntax(c, 'NAME [TEMPLATE]')
      c.summary = 'Return the template for an existing or new deployment'
      c.description = <<~DESC
        Renders the template for the `NAME` deployment. Existing deployments
        will always render the saved template and replacements.

        If the deployment does not exist, the `TEMPLATE` and `--params`
        options are used instead. See the 'deploy' command for valid inputs
        for these inputs.
      DESC
      c.option '-t', '--template PATH', String, <<~DESC
        Template path for a new deployment
      DESC
      c.option '--params STRING', String, <<~DESC
        Values to be replaced for a new deployment
      DESC
      action(c, Commands::Deploy, method: :render)
    end
  end
end
