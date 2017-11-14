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
require 'azure_sdk'

module Cloudware
  module Provider
    class Azure
      attr_accessor :name

      def initialize
        provider = MsRestAzure::ApplicationTokenProvider.new(
                   ENV['AZURE_TENANT_ID'],
                   ENV['AZURE_CLIENT_ID'],
                   ENV['AZURE_CLIENT_SECRET'])
        credentials = MsRest::TokenCredentials.new(provider)
        options = {
          credentials: credentials,
          subscription_id: ENV['AZURE_SUBSCRIPTION_ID']
        }
        @client = Azure::Resources::Profiles::Latest::Mgmt::Client.new(options)
      end
      
      def create_domain(name, networkcidr, subnets)
        @template = File.read(File.expand_path(File.join(__dir__, '../../templates/azure-network-base.json')))
      end
    end
  end
end
