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
require 'azure_mgmt_resources'

Resources = Azure::Resources::Profiles::Latest::Mgmt

module Cloudware
  class Azure
    attr_accessor :name, :id, :networkcidr, :prvsubnetcidr, :mgtsubnetcidr, :region, :iptail, :type

    def initialize
      subscription_id = ENV['AZURE_SUBSCRIPTION_ID']
      provider = MsRestAzure::ApplicationTokenProvider.new(
        ENV['AZURE_TENANT_ID'],
        ENV['AZURE_CLIENT_ID'],
        ENV['AZURE_CLIENT_SECRET']
      )
      credentials = MsRest::TokenCredentials.new(provider)
      options = {
        credentials: credentials,
        subscription_id: subscription_id
      }
      @client = Resources::Client.new(options)
    end

    def create_domain
      unless resource_group_exists == true
        create_resource_group
      end

      t = 'azure-network-base.json'
      @params = {
        infrastructure: @name,
        networkCIDR: @networkcidr,
        prvSubnetCIDR: @prvsubnetcidr,
        mgtSubnetCIDR: @mgtsubnetcidr
      }
      deploy(t, 'domain')
    end

    def list_domains
      d = []
      list_resource_groups.each do |i|
        resources = @client.resources.list_by_resource_group(i[0])
        resources.each do |r|
          next unless r.name == 'network'
          d.push([i[0],
                  r.tags['cloudware_network_cidr'],
                  r.tags['cloudware_prv_subnet_cidr'],
                  r.tags['cloudware_mgt_subnet_cidr'],
                  'azure'])
        end
      end
      d
    end

    def destroy_domain; end

    def create_machine
      puts 'Creating new machine:'
      puts "Name: #{@name}"
    end

    def list_machine; end

    def destroy_machine; end

    def deploy(template, type)
      t = File.read(File.expand_path(File.join(__dir__, "../../templates/#{template}")))
      d = @client.model_classes.deployment.new
      d.properties = @client.model_classes.deployment_properties.new
      d.properties.template = JSON.parse(t)
      d.properties.mode = Resources::Models::DeploymentMode::Incremental
      d.properties.parameters = Hash[*@params.map { |k, v| [k, { value: v }] }.flatten]
      debug_settings = @client.model_classes.debug_setting.new
      debug_settings.detail_level = 'requestContent, responseContent'
      d.properties.debug_setting = debug_settings
      puts '==> Creating new deployment. This may take a while..'
      @client.deployments.create_or_update(name, type.to_s, d)
      operation_results = @client.deployment_operations.list(@name, type.to_s)
      unless operation_results.nil?
        operation_results.each do |operation_result|
          until operation_result.properties.provisioning_state == 'Succeeded'
            sleep(1)
          end
        end
      end
      puts '==> Deployment succeeded'
    end

    def resource_group_exists
      i = []
      @client.resource_groups.list.each do |group|
        next if group.tags.nil?
        next if group.tags['cloudware_id'].nil?
        unless group.tags['cloudware_id'] == @name
          return false
        else return true; end
      end
    end

    def create_resource_group
      params = @client.model_classes.resource_group.new.tap do |r|
        r.location = @region
        r.tags = {
          cloudware_id: @id,
          cloudware_domain: @name,
          region: @region
        }
      end
      @client.resource_groups.create_or_update(@name, params)
    end

    def list_resource_groups
      i = []
      @client.resource_groups.list.each do |group|
        next if group.tags.nil?
        next if group.tags['cloudware_id'].nil?
        i.push([group.tags['cloudware_domain'],
                group.tags['region'],
                'azure'])
      end
      i
    end
  end
end
