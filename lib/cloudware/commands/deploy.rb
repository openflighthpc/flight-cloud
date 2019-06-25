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

require 'cloudware/list_templates'
require 'tty-prompt'

module Cloudware
  module Commands
    class Deploy < Command
      def self.delayed_require
        super
        require 'cloudware/replacement_factory'
      end

      def run!(name, raw_path = nil, params: nil, group: nil)
        machines = if group
                     get_machines_in_group(name)
                   else
                    [name]
                   end

        machines.each do |m|
          cur_dep = if raw_path
            create_deployment(m, raw_path, params: params)
          else
            Models::Deployment.read!(__config__.current_cluster, m)
          end
          raise_if_deployed(cur_dep)

          dependencies = cur_dep.replacements.select { |key, value|
            # Select only values to be resolved
            value.include? "*"
          }.each_value.uniq.map { |value|
            Models::Deployment.read(__config__.current_cluster, (value.delete "*"))
          }

          dependencies.each do |d|
            unless d.deployed
              puts "Deploying dependency: #{d.name}"
              deploy(d.name)
            end
          end

          puts "Deploying: #{cur_dep.path}"
          deploy(m)
        end
      end

      def prompt_for_params(errors)
        puts "Please provide values for the following missing parameters:"
        puts "(Note: Use the format of *<resource_name> to reference a resource)"
        prompt = TTY::Prompt.new

        replacements = {}
        errors.each do |e|
          replacements[e.to_s.delete('%').to_sym] = prompt.ask("#{e}:")
        end

        return replacements
      end

      def render(name, template = nil, params: nil)
        cluster = __config__.current_cluster
        deployment = Models::Deployment.read_or_new(cluster, name)
        unless deployment.template_path
          path = resolve_template(template, error_missing: true)
          deployment.template_path = path
          deployment.replacements = ReplacementFactory.new(cluster, name)
                                                      .build(params)
        end
        puts deployment.template
      end

      def list_templates(verbose: false)
        list = Models::Cluster.load(__config__.current_cluster).templates
        if verbose && list.any?
          list.human_paths.each do |human_path, abs_path|
            puts "#{human_path} => #{abs_path}"
          end
        elsif list.any?
          list.shorthand_paths.each do |human_path, _|
            puts human_path
          end
        else
          raise UserError, 'No templates found'
        end
      end

      private

      def create_deployment(name, raw_path, params: nil)
        replacements = ReplacementFactory.new(__config__.current_cluster, name)
                                         .build(params)
        Models::Deployment.create!(
          __config__.current_cluster, name,
          template: raw_path,
          replacements: replacements
        ) { |errors| prompt_for_params(errors) }
      end

      def raise_if_deployed(dep)
        return unless dep.deployed
        raise InvalidInput, "'#{dep.name}' is already running"
        ERROR
      end

      def deploy(machine)
        with_spinner('Deploying resources...', done: 'Done') do
          dep = Models::Deployment.deploy!(__config__.current_cluster, machine)
          if dep.deployment_error
            raise DeploymentError, <<~ERROR.chomp
               An error has occured. Please see for further details:
              `#{Config.app_name} list deployments --verbose`
            ERROR
          end
        end
      end
    end
  end
end
