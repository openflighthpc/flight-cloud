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

Resources = Azure::Resources::Profiles::Latest::Mgmt

module Cloudware
  class Azure
    attr_accessor :name, :networkcidr, :subnets, :region, :infrastructure

    def initialize
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

    def create_infrastructure
      params = @client.model_classes.resource_group.new.tap do |r|
        r.location = region
        r.tags = {
          cloudware_id: name,
          region: region
        }
      end
      puts "==> Creating infrastructure: #{@name}"
      @client.resource_groups.create_or_update(@name, params)
    end

    def list_infrastructure
      i = Array.new
      @client.resource_groups.list.each { |group|
        next if group.tags.nil?
        g = group.tags
        next if g["cloudware_id"].nil?
        i.push(g["cloudware_id"].to_s)
      }
      "#{i}"
    end

    def destroy_infrastructure
      puts "==> Destroying infrastructure #{@name}. This may take a while.."
      @client.resource_groups.delete(@name)
      puts "==> Infrastructure group #{@name} destroyed."
    end

    def create_domain
    end

    def list_domain
    end

    def destroy_domain
    end

    def create_machine
    end

    def list_machine
    end

    def destroy_machine
    end
  end
end
