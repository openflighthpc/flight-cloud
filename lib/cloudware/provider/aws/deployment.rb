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
# You hould have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================
module Cloudware
  class Aws
    module Deployment
        def create
            stack_deploy(render_stack_name,
                         render_stack_template,
                         render_params)
        end

        def destroy
        end

        private

        def domain
            @domain ||= Cloudware::Domain.new(options)
        end

        def render_stack_name
            if @options[:machine]
                "#{@options[:machine]}-#{@options[:domain]}"
            else
                "#{@options[:domain]}"
            end
        end

        def render_params
            if @options[:machine]
                machine_parameters
            else
                domain_parameters
            end
        end

        def render_machine_template(type = @options[:type])
            File.read(File.expand_path(File.join(__dir__, "../../providers/aws/templates/machine-#{type}.json")))
        end

        def machine_parameters
            [
                { parameter_key: 'cloudwareDomain',
                  parameter_value: @options[:domain] },
                { parameter_key: 'cloudwareId',
                  parameter_value: @options[:id] },
                { parameter_key: 'mgtIp',
                  parameter_value: @options[:mgtip] },
                { parameter_key: 'prvIp',
                  parameter_value: @options[:prvip] },
                { parmeter_key: 'vmRole',
                  parameter_value: @options[:role] },
                { parameter_key: 'vmType',
                  parameter_value: @options[:type] },
                { parameter_key: 'vmName',
                  parameter_value: @options[:machine] },
                { parameter_key: 'networkId',
                  parameter_value: }
            ]
        end

        def stack_deploy(name, template, params)
            begin
                cfn.create_stack stack_name: name,
                    template_body: template,
                    parameters: params
                cfn.wait_until :stack_create_complete, stack_name: name
            rescue CloudFormation::Errors::ServiceError => error
                log.error("Failed waiting for #{name} to create: #{error.message}")
            end
        end

        def stack_destroy
        end
    end
  end
end
