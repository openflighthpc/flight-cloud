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
          instance.stop
        end

        def on
          instance.start
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
