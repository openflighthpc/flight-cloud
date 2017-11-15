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
    attr_accessor :name, :networkcidr, :prvsubnetcidr, :mgtsubnetcidr, :region, :infrastructure, :iptail, :type

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
      i
    end

    def destroy_infrastructure
      puts "==> Destroying infrastructure #{@name}. This may take a while.."
      @client.resource_groups.delete(@name)
      puts "==> Infrastructure group #{@name} destroyed."
    end

    def create_domain
      t = "azure-network-base.json"
      @params = {
        infrastructure: @infrastructure,
        networkCIDR: @networkcidr,
        prvSubnetCIDR: @prvsubnetcidr,
        mgtSubnetCIDR: @mgtsubnetcidr
      }
      deploy(t, 'domain')
    end

    def list_domains
      d = Array.new
      list_infrastructure.each { |i|
        resources = @client.resources.list_by_resource_group(i)
        resources.each { |r|
          next unless r.name == "network"
          d.push([i,
                  r.tags["cloudware_network_cidr"],
                  r.tags["cloudware_prv_subnet_cidr"],
                  r.tags["cloudware_mgt_subnet_cidr"],
                  'azure'])
        }
      }
      d
    end

    def destroy_domain
    end

    def create_machine
      puts "Creating new machine:"
      puts "Name: #{@name}"
    end

    def list_machine
    end

    def destroy_machine
    end

    def deploy(template, type)
      t = File.read(File.expand_path(File.join(__dir__, "../../templates/#{template}")))
      d = @client.model_classes.deployment.new
      d.properties = @client.model_classes.deployment_properties.new
      d.properties.template = JSON.parse(t)
      d.properties.mode = Resources::Models::DeploymentMode::Incremental
      d.properties.parameters = Hash[*@params.map{ |k, v| [k,  {value: v}] }.flatten]
      debug_settings = @client.model_classes.debug_setting.new
      debug_settings.detail_level = 'requestContent, responseContent'
      d.properties.debug_setting = debug_settings
      puts "==> Creating new deployment. This may take a while.."
      @client.deployments.create_or_update(infrastructure, "#{type}", d)
      operation_results = @client.deployment_operations.list(@infrastructure, "#{type}")
      unless operation_results.nil?
        operation_results.each do |operation_result|
          until operation_result.properties.provisioning_state == "Succeeded"
            sleep(1)
          end
        end
      end
      puts "==> Deployment succeeded"
    end
  end
end
