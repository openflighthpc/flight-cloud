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
    LOW_PRIORITY = 1
    MID_PRIORITY = 10
    LARGE_PRIORITY = 100

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

    command 'cluster create' do |c|
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
      c.priority = LOW_PRIORITY + 2
      c.summary = 'Show the current and available clusters'
      c.description = <<~DESC
        Shows a list of clusters that have been previously deployed to
      DESC
      action(c, Commands::ClusterCommand, method: :list)
    end

    command 'cluster switch' do |c|
      cli_syntax(c, 'CLUSTER')
      c.priority = LOW_PRIORITY + 4
      c.summary = 'Change the current cluster to CLUSTER'
      action(c, Commands::ClusterCommand, method: :switch)
    end

    command 'cluster delete' do |c|
      cli_syntax(c, 'CLUSTER')
      c.priority = LOW_PRIORITY + 1
      c.summary = 'Destroys the deployments and deletes the cluster'
      action(c, Commands::ClusterCommand, method: :delete)
    end

    command 'cluster show' do |c|
      cli_syntax(c)
      c.priority = LOW_PRIORITY + 3
      c.summary = "View details about the cluster's deployment"
      c.option '-v', '--verbose', 'Show full error messages'
      proxy_opts = { level: :domain, method: :deployables, named: false }
      c.action(&Commands::List.proxy(**proxy_opts))
    end

    [:list, :show].each do |cmd|
      proxy_opts = {
        level: (cmd == :list ? :cluster : :node),
        index: :nodes,
        method: :deployables,
        named: (cmd == :show)
      }

      command "node #{cmd}" do |c|
        if cmd == :list
          cli_syntax(c)
          c.priority = LOW_PRIORITY + 2
          c.summary = 'List all the nodes within the cluster'
        else
          cli_syntax(c, 'NODE')
          c.priority = LOW_PRIORITY + 3
          c.summary = 'View the details about a particular node'
        end
        c.option '-v', '--verbose', 'Show full error messages'
        c.action(&Commands::List.proxy(**proxy_opts))
      end
    end

    [:group, :node].each do |level|
      command level do |c|
        cli_syntax(c)
        c.sub_command_group = true
        c.summary = "View, manage, and deploy #{ level == :domain ? 'the' : 'a' } #{level}"
      end
    end

    [:domain, :group, :node].each do |level|
      cli_level = (level == :domain ? :cluster : level)

      proxy_opts = {
        level: level,
        method: (level == :group ? :index : :deployable),
        named: (level != :domain)
      }

      command "#{cli_level} action deploy" do |c|
        multilevel_cli_syntax(c, level, '[PARAMS...]')
        c.priority = LARGE_PRIORITY
        c.summary = 'Create the templated resources on the provider'
        c.action(&Commands::Deploy.proxy(**proxy_opts))
      end

      command "#{cli_level} action destroy" do |c|
        multilevel_cli_syntax(c, level)
        c.summary = 'Teardown the resouces on the provider'
        c.priority = LARGE_PRIORITY
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

    command "node create" do |c|
      multilevel_cli_syntax(c, :node, 'TEMPLATE')
      c.description = "Add a new node to the cluster"
      c.priority = LOW_PRIORITY
      proxy_opts = {
        level: :node, method: :deployable, named: true
      }
      c.action(&Commands::Create.proxy(**proxy_opts))
    end

    [:domain, :node].each do |level|
      cli_level = (level == :domain ? :cluster : level)

      command  "#{cli_level} template" do |c|
        multilevel_cli_syntax(c, level)
        c.priority = MID_PRIORITY + 1
        c.summary = "View and modify the #{cli_level} template"
        c.sub_command_group = true
      end

      command  "#{cli_level} parameters" do |c|
        multilevel_cli_syntax(c, level)
        c.priority = MID_PRIORITY + 2
        c.summary = "View and modify the #{cli_level} parameters"
        c.sub_command_group = true
      end

      command "#{cli_level} template edit" do |c|
        multilevel_cli_syntax(c, level, '[TEMPLATE]')
        c.summary = 'Update the cloud template'
        c.description = <<~DESC
          Open the #{cli_level} template in the editor so it can be updated.

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

      command "#{cli_level} template show" do |c|
        multilevel_cli_syntax(c, level)
        c.summary = "Print the un rendered #{cli_level} template to stdout"
        proxy_opts = { level: level, method: :show, named: (level != :domain) }
        c.action(&Commands::Render.proxy(**proxy_opts))
      end

      command "#{cli_level} template render" do |c|
        multilevel_cli_syntax(c, level)
        c.summary = "Return the template the #{cli_level}"
        proxy_opts = { level: level, method: :render, named: (level != :domain) }
        c.action(&Commands::Render.proxy(**proxy_opts))
      end

      command "#{cli_level} parameters show" do |c|
        multilevel_cli_syntax(c, level)
        c.summary = 'Display the replacements used during render'
        proxy_opts = { level: level, method: :show_params, named: (level != :domain) }
        c.action(&Commands::Render.proxy(**proxy_opts))
      end

      command "#{cli_level} parameters update" do |c|
        multilevel_cli_syntax(c, level, 'PARAMS...')
        c.summary = "Update the #{level}'s parameters"
        proxy_opts = { level: level, method: :run, named: (level != :domain) }
        c.action(&Commands::Update.proxy(**proxy_opts))
      end

      command "#{level} delete" do |c|
        multilevel_cli_syntax(c, level)
        c.priority = LOW_PRIORITY + 1
        c.summary = "Permanently remove the #{level} from the cluster"
        c.description = <<~DESC
          Permanently delete the configuration file and associated template.
          This action will error if the deployment is currently running.

          To circumvent the error, either:
            1. Stop the deployment with '#{level} destroy' OR
            2. Abandon the resources using the --force flag [DANGER]

          Abandoning the resources will leave them running on the provider.
          They will need to be stopped manually via some other means.
          The provider may continue charging for these resources until they
          are stopped.
        DESC
        proxy_opts = { level: level, method: :deployable, named: true }
        c.action(&Commands::Delete.proxy(**proxy_opts))
      end
    end

    command 'group list' do |c|
      cli_syntax(c)
      c.priority = LOW_PRIORITY + 2
      c.description = 'List all groups within the cluster'
      proxy_opts = { level: :cluster, index: :groups, named: false }
      c.action(&Commands::List.proxy(**proxy_opts))
    end

    command 'group members' do |c|
      cli_syntax(c, 'GROUP')
      c.priority = MID_PRIORITY
      c.description = 'View and manage all the members within the group'
      c.sub_command_group = true
    end

    command 'group members list' do |c|
      cli_syntax(c, 'GROUP')
      c.description = 'View all the nodes within the group'
      proxy_opts = { level: :group, named: true, method: :show}
      c.action(&Commands::Group.proxy(**proxy_opts))
    end

    command 'group create' do |c|
      cli_syntax(c, 'GROUP')
      c.priority = LOW_PRIORITY
      c.description = 'Define a new empty group'
      c.action(&Commands::Create.proxy(level: :group, named: true))
    end

    [:cluster, :group, :node].each do |level|
      command "#{level} action" do |c|
        multilevel_cli_syntax(c, level)
        c.priority = MID_PRIORITY
        if level == :nodes
          c.description = 'Run a command on the node'
        else
          c.description = 'Run a command over the nodes'
        end
        c.sub_command_group = true
      end
    end

    command "node action" do |c|
      cli_syntax(c)
      c.description = 'Run a command on the node'
      c.sub_command_group = true
      c.priority = MID_PRIORITY
    end

    command "group members action" do |c|
      multilevel_cli_syntax(c, :group)
      c.description = 'Run a command over the nodes'
      c.sub_command_group = true
    end

    [:group, :node].each do |level|
      command "#{level} action power-status" do |c|
        multilevel_cli_syntax(c, level)
        if level == :node
          c.description = 'Check the power state of the node'
        else
          c.description = 'Check the power state of the nodes'
        end
        proxy_opts = { level: level, method: :status_cli, named: (level != :cluster) }
        c.action(&Commands::ScopedPower.proxy(**proxy_opts))
      end

      command "#{level} action power-off" do |c|
        multilevel_cli_syntax(c, level)
        if level == :node
          c.description = 'Turn the node off'
        else
          c.description = 'Turn the nodes off'
        end
        proxy_opts = { level: level, method: :off_cli, named: (level != :cluster) }
        c.action(&Commands::ScopedPower.proxy(**proxy_opts))
      end

      command "#{level} action power-on" do |c|
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
