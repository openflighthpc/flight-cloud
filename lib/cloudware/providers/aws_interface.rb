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

require 'aws-sdk-cloudformation'
require 'aws-sdk-ec2'
require 'cloudware/providers/base'

module Cloudware
  module Providers
    module AWSInterface
      class Credentials < Base::Credentials
        def self.build
          Aws::Credentials.new(config.access_key_id, config.secret_access_key)
        end

        def self.required_keys
          [:access_key_id, :secret_access_key]
        end

        private_class_method

        def self.config
          Config.aws
        end
      end

      class Machine < Base::Machine
        def status
          instance.state.name
        end

        def off
          instance.stop.stopping_instances.first.current_state.name
        rescue Aws::EC2::Errors::IncorrectInstanceState
          raise ProviderError, <<~ERROR.chomp
            The instance is not in a state from which it can be turned off
          ERROR
        end

        def on
          instance.start.starting_instances.first.current_state.name
        rescue Aws::EC2::Errors::IncorrectInstanceState
          raise ProviderError, <<~ERROR.chomp
            The instance is not in a state from which it can be turned on
          ERROR
        end

        private

        def instance
          Aws::EC2::Resource.new(
            region: region, credentials: credentials
          ).instance(machine_id)
        end
        memoize :instance
      end

      class Client < Base::Client
        def deploy(tag, template)
          client.create_stack(stack_name: tag, template_body: template)
          client.wait_until(:stack_create_complete, stack_name: tag)
                .stacks
                .first
                .outputs
                .each_with_object({}) do |output, memo|
                  memo[output.output_key] = output.output_value
                end
        end

        def destroy(tag)
          client.delete_stack(stack_name: tag)
          client.wait_until(:stack_delete_complete, stack_name: tag)
        end

        private

        def client
          Aws::CloudFormation::Client.new(
            region: region, credentials: credentials
          )
        end
        memoize :client
      end
    end
  end
end
