# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

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
      cli_syntax(c, 'PROVIDER CLUSTER')
      c.summary = 'Create a new cluster'
      c.description = <<~DESC
        Create a new cluster that can be identified by CLUSTER. The cluster
        must not already exist. The resources will be deployed to the
        specified PROVIDER. Use the `--import` option to import templates
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

    command 'cluster delete' do |c|
      cli_syntax(c, 'CLUSTER')
      c.summary = 'Destroys the deployments and deletes the cluster'
      action(c, Commands::ClusterCommand, method: :delete)
    end

    command 'deploy' do |c|
      cli_syntax(c, 'NAME [TEMPLATE]')
      c.summary = 'Deploy new resource(s) define by a template'
      c.description = <<-DESC.strip_heredoc
        When called with a single argument, it will deploy a currently existing
        deployment: NAME. This will result in an error if the deployment does
        not exist or is currently in a deployed state.

        Calling it with a second argument will try and create a new deployment
        called NAME with the specified TEMPLATE. The TEMPLATE references the
        internal template which have been imported. Alternatively it can be
        an absolute path to a template file.

        In either case, the template is read and sent to the provider. The
        template is read each time it is re-deployed. Be careful not to delete
        or modify it.

        The templates also support basic rendering of parameters from the
        command line. This is intended to provide minor tweaks to the templates
        (e.g. IPs or names).
      DESC
      c.option '-p', '--params \'<REPLACE_KEY=*IDENTIFIER[.OUTPUT_KEY] >...\'',
               String, 'A space separated list of keys to be replaced'
      c.option '-g', '--group', 'Deploy all resources within the specified group'
      action(c, Commands::Deploy)
    end

    command 'destroy' do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Stop a running deployment'
      c.description = <<~DESC
        Destroys the deployment on the providers platform and flags it
        as offline. This action does not remove the configuration file,
        allowing it to be redeployed easily.

        Once the deployment is offline, the configuration file can be
        permanently removed using the 'delete' command.
      DESC
      c.option '-g', '--group', 'Destroy all deployments within the specified group'
      action(c, Commands::Destroy)
    end

    command 'delete' do |c|
      cli_syntax(c, 'NAME')
      c.summary = 'Remove the deployments configuration file'
      c.description = <<~DESC
        Deletes the configuration file for the deployment NAME. This action
        will error if the resources are currently running. The resources can
        be stop using the 'destroy' command.

        The configuration of a currently running deployment can be deleted
        using the '--force' flag. This will not destroy the remote resources
      DESC
      c.option '--force', 'Delete the deployment regardless if running'
      c.option '-g', '--group', 'Delete all deployments within the specified group'
      action(c, Commands::Destroy, method: :delete)
    end

    # TODO: Fix the import command
    #command 'import' do |c|
    #  cli_syntax(c, 'ZIP_PATH')
    #  c.summary = 'Add templates to the cluster'
    #  c.description = <<~DESC.split("\n\n").map(&:squish).join("\n")
    #    Imports the '#{Config.provider}' templates into the internal cache. The
    #    ZIP_PATH must be a zip file containing an '#{Config.provider}'
    #    directory.\n\n

    #    These templates can then be used to deploy resource using:\n
    #    #{Config.app_name} deploy foo template
    #  DESC
    #  action(c, Commands::Import)
    #end

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
      c.option '-a', '--all', 'Include offline deployments'
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
        Perform the '#{action}' action on machine in group '#{cli_attr}'
      DESC
    end

    command 'power status' do |c|
      shared_power_attr(c)
      c.description = 'Check the power state of a machine'
      action(c, Commands::Power, method: :status_cli)
    end

    command 'power off' do |c|
      shared_power_attr(c)
      c.description = 'Turn the machine off'
      action(c, Commands::Power, method: :off_cli)
    end

    command 'power on' do |c|
      shared_power_attr(c)
      c.description = 'Turn the machine on'
      action(c, Commands::Power, method: :on_cli)
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

    # command 'configure' do |c|
    #   cli_syntax(c)
    #   c.description = 'Configure access details for the current provider'
    #   action(c, Commands::Configure)
    # end
  end
end
