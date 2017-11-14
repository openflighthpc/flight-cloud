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
require 'azure_mgmt_resources'
require 'terminal-table'

Resources = Azure::Resources::Profiles::Latest::Mgmt

module Cloudware
  module Provider
    class Azure
      attr_accessor :name

      def initialize
        client
      end

      def client
        subscription_id = ENV['AZURE_SUBSCRIPTION_ID']
        provider = MsRestAzure::ApplicationTokenProvider.new(
                   ENV['AZURE_TENANT_ID'],
                   ENV['AZURE_CLIENT_ID'],
                   ENV['AZURE_CLIENT_SECRET'])
        credentials = MsRest::TokenCredentials.new(provider)
        options = {
          credentials: credentials,
          subscription_id: subscription_id
        }
        @client = Resources::Client.new(options)
      end
      
      def create_domain(name, networkcidr, subnets, region)
        @template = File.read(File.expand_path(File.join(__dir__, '../../templates/azure-network-base.json')))

        check_if_domain_exists(name)

        # Ensure the resource group is created before deploying the first template
        params = @client.model_classes.resource_group.new.tap do |r|
          r.location = region
          r.tags = {
            cloudware_domain: name,
            network_cidr: networkcidr,
            region: region
          }
        end
        puts "==> Creating resource group #{name}"
        @client.resource_groups.create_or_update(name, params)
      end

      def deploy(template, params)
      end

      def list_domains
        rows = []
        @client.resource_groups.list.each { |group|
          next if group.tags.nil?
          cloudwaredomain = group.tags
          rows << [cloudwaredomain["cloudware_domain"],
                   cloudwaredomain["network_cidr"],
                   cloudwaredomain["region"]]
        }
        table = Terminal::Table.new :headings => ['Domain name', 'Network CIDR', 'Region'], :rows => rows
        puts table
      end

      def check_if_domain_exists(name)
        @client.resource_groups.list.each { |group|
          next if group.name != name
          if group.name == name
            abort("==> Domain #{name} already exists")
          end
        }
      end

      def destroy_domain(name)
        puts "==> Destroying domain #{name}. This may take a while.."
        @client.resource_groups.delete(name)
        puts "==> Resource group #{name} destroyed"
      end

    end
  end
end
