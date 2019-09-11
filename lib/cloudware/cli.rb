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

    def self.multilevel_cli_syntax(command, level, args_str = '')
      case level
      when :group
        cli_syntax(command, "GROUP #{args_str}".chomp)
      when :stack
        cli_syntax(command, "STACK #{args_str}".chomp)
      when :node
        cli_syntax(command, "NODE #{args_str}".chomp)
      else
        cli_syntax(command, args_str)
      end
    end

    def self.cli_syntax(command, args_str = '')
      command.hidden = true if command.name.split.length > 1
      command.syntax = <<~SYNTAX.squish
        #{program(:name)} #{command.name} #{args_str}
      SYNTAX
    end

    command 'configure' do |c|
      cli_syntax(c)
      c.description = 'Configure access details for the current provider'
      action(c, Commands::Configure)
    end

    command 'cluster' do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.summary = 'Manage and overview the current cluster profile'
    end

    command 'cluster init' do |c|
      cli_syntax(c, 'CLUSTER PROVIDER')
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

    command('cluster list') do |c|
      cli_syntax(c)
      c.summary = 'Show the current and available clusters'
      c.description = <<~DESC
        Shows a list of clusters that have been previously deployed to
      DESC
      action(c, Commands::ClusterCommand, method: :list)
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

    [:domain, :group, :node].each do |level|
      command level do |c|
        cli_syntax(c)
        c.sub_command_group = true
        c.summary = "View, manage, and deploy #{ level == :domain ? 'the' : 'a' } #{level}"
      end
    end

    command :stack do |c|
      cli_syntax(c)
      c.sub_command_group = true
      c.hidden = true
      c.summary = 'Volatile'
    end

    command 'node create' do |c|
      cli_syntax(c, 'NAME TEMPLATE')
      c.description = 'Add a new node to the cluster'
      c.option '--groups GROUPS', <<~DESC.squish
        Set which GROUPS the node belongs to. This option is ignored when
        creating a domain. The GROUPS must be given as a comma separated list.
      DESC
      action(c, Commands::Create)
    end

    # TODO: The old deploy command is being maintained for reference, once the
    # functionality has been replicated, remove this code block
    #
    # command 'deploy' do |c|
    #   cli_syntax(c, 'NAME [TEMPLATE]')
    #   c.summary = 'Deploy new resource(s) define by a template'
    #   c.description = <<-DESC.strip_heredoc
    #     When called with a single argument, it will deploy a currently existing
    #     deployment: NAME. This will result in an error if the deployment does
    #     not exist or is currently in a deployed state.

    #     Calling it with a second argument will try and create a new deployment
    #     called NAME with the specified TEMPLATE. The TEMPLATE references the
    #     internal template which have been imported. Alternatively it can be
    #     an absolute path to a template file.

    #     In either case, the template is read and sent to the provider. The
    #     template is read each time it is re-deployed. Be careful not to delete
    #     or modify it.

    #     The templates also support basic rendering of parameters from the
    #     command line. This is intended to provide minor tweaks to the templates
    #     (e.g. IPs or names).
    #   DESC
    #   c.option '-p', '--params \'<REPLACE_KEY=*IDENTIFIER[.OUTPUT_KEY] >...\'',
    #            String, 'A space separated list of keys to be replaced'
    #   c.option '-g', '--group', 'Deploy all resources within the specified group'
    #   action(c, Commands::Deploy)
    # end

    ['domain', 'cluster_nodes', 'stack', 'group_nodes', 'node'].each do |type|
      level = type.chomp('_nodes').to_sym
      index = type.match(/(?<=_)\w+\Z/)&.to_s&.to_sym
      proxy_opts = {
        level: level,
        index: index,
        method: (index ? nil : :run!),
        named: (level != :domain)
      }

      command "#{level} deploy#{ "-#{index}" if index }" do |c|
        multilevel_cli_syntax(c, level, '[PARAMS...]')
        c.summary = 'Create the templated resources on the provider'
        c.action(&Commands::Deploy.proxy(**proxy_opts))
      end

      command "#{level} destroy#{ "-#{index}" if index }" do |c|
        multilevel_cli_syntax(c, level)
        c.summary = 'Teardown the resouces on the provider'
        c.description = <<~DESC
          Destroys the resources on the providers platform and flags it
          as offline. This action does not remove the configuration file,
          allowing it to be redeployed easily.

          Once the deployment is offline, the configuration file can be
          permanently removed using the 'delete' command.
        DESC
        c.action(&Commands::Destroy.proxy(**proxy_opts))
      end
    end

    command 'node delete' do |c|
      cli_syntax(c, 'NODE')
      c.summary = 'Remove the node from the cluster'
      c.description = <<~DESC
        Deletes the configuration file for the NODE. This action will error if
        the node is currently running. The node cane be stopped using the
        'destroy' command.

        The configuration of a currently running node can be deleted
        using the '--force' flag. This will not destroy the remote resources
      DESC
      c.option '--force', 'Delete the deployment regardless if running'
      proxy_opts = { level: :node, method: :delete, named: true }
      c.action(&Commands::Destroy.proxy(**proxy_opts))
    end

    [:domain, :stack, :node].each do |level|
      command "#{level} edit" do |c|
        multilevel_cli_syntax(c, level, '[TEMPLATE]')
        c.summary = 'Update the cloud template'
        c.description = <<~DESC
          Open the #{level} template in the editor so it can be updated.

          Alternatively the template can be replaced by a system file by specifing
          the optional TEMPLATE argument. TEMPLATE should give the file path to the
          new file, which will be copied into place. This action will skip opening the
          file in the editor.
        DESC
        proxy_opts = {
          level: level,
          method: (level == :domain ? :domain : :run),
          named: (level != :domain)
        }
        c.action(&Commands::Edit.proxy(**proxy_opts))
      end

      command "#{level} render" do |c|
        cli_syntax(c, 'NAME')
        c.summary = "Return the template the #{level}"
        proxy_opts = { level: level, method: :render, named: (level != :cluster) }
        c.action(&Commands::Deploy.proxy(**proxy_opts))
      end

      command "#{level} update" do |c|
        multilevel_cli_syntax(c, level, 'PARAMS...')
        c.summary = "Update the #{level}'s parameters"
        proxy_opts = { level: level, method: :run, named: (level != :domain) }
        c.action(&Commands::Update.proxy(**proxy_opts))
      end
    end

    command 'import' do |c|
      cli_syntax(c, 'PATH')
      c.summary = 'Add templates to the cluster'
      action(c, Commands::Import)
    end

    command 'list' do |c|
      cli_syntax(c)
      c.description = 'List all the previous deployed templates'
      c.option '-a', '--all', 'Include offline deployments'
      c.option '-g GROUP', '--group GROUP', 'Filter the list by group'
      c.option '-v', '--verbose', 'Show full error messages'
      action(c, Commands::Lists::Deployment)
    end

    command 'group list' do |c|
      cli_syntax(c)
      c.description = 'List all groups within the cluster'
      action(c, Commands::Lists::Deployment, method: :list_groups)
    end

    [:cluster, :group, :node].each do |level|
      command "#{level} power-status" do |c|
        multilevel_cli_syntax(c, level)
        if level == :node
          c.description = 'Check the power state of the node'
        else
          c.description = 'Check the power state of the nodes'
        end
        proxy_opts = { level: level, method: :status_cli, named: (level != :cluster) }
        c.action(&Commands::ScopedPower.proxy(**proxy_opts))
      end

      command "#{level} power-off" do |c|
        multilevel_cli_syntax(c, level)
        if level == :node
          c.description = 'Turn the node off'
        else
          c.description = 'Turn the nodes off'
        end
        proxy_opts = { level: level, method: :off_cli, named: (level != :cluster) }
        c.action(&Commands::ScopedPower.proxy(**proxy_opts))
      end

      command "#{level} power-on" do |c|
        multilevel_cli_syntax(c, level)
        if level == :node
          c.description = 'Turn the node on'
        else
          c.description = 'Turn the nodes on'
        end
        proxy_opts = { level: level, method: :on_cli, named: (level != :cluster) }
        c.action(&Commands::ScopedPower.proxy(**proxy_opts))
      end
    end
  end
end
