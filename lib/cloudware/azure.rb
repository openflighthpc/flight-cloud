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
      log.info('Loading Azure client')
      @client = Resources::Client.new(options)
    end

    def create_domain(name, id, networkcidr, prvsubnetcidr, mgtsubnetcidr, region)
      abort('Domain already exists') if resource_group_exists?(name)
      create_resource_group(region, id, name)

      t = 'azure/domain.json'
      params = {
        cloudwareDomain: name,
        cloudwareId: id,
        networkCIDR: networkcidr,
        prvSubnetCIDR: prvsubnetcidr,
        mgtSubnetCIDR: mgtsubnetcidr
      }
      deploy(t, 'domain', params, name)
    end

    def domains
      @domains = {}
      resource_groups.each do |g|
        log.info("Listing available resources in group #{g}")
        resources = @client.resources.list_by_resource_group(g)
        resources.each do |r|
          next unless r.tags['cloudware_resource_type'] == 'domain'
          next unless r.type == 'Microsoft.Network/virtualNetworks'
          @domains.merge!(r.tags['cloudware_domain'] => {
                            domain: r.tags['cloudware_domain'],
                            id: r.tags['cloudware_id'],
                            network_cidr: r.tags['cloudware_network_cidr'],
                            prv_subnet_cidr: r.tags['cloudware_prv_subnet_cidr'],
                            mgt_subnet_cidr: r.tags['cloudware_mgt_subnet_cidr'],
                            provider: 'azure',
                            region: r.tags['cloudware_domain_region']
                          })
        end
      end
      @domains
    end

    def create_machine(name, domain, id, prvip, mgtip, type, size, _region)
      t = "azure/machine-#{type}.json"
      params = {
        cloudwareDomain: domain,
        cloudwareId: id,
        vmName: name,
        vmType: size,
        prvSubnetIp: prvip,
        mgtSubnetIp: mgtip
      }
      deploy(t, name, params, domain)
    end

    def machines
      @machines = {}
      resource_groups.each do |g|
        resources = @client.resources.list_by_resource_group(g)
        resources.each do |r|
          next unless r.tags['cloudware_resource_type'] == 'machine'
          next unless r.type == 'Microsoft.Compute/virtualMachines'
          @machines.merge!(r.tags['cloudware_machine_name'] => { domain: r.tags['cloudware_domain'], role: r.tags['cloudware_machine_role'], prv_ip: r.tags['cloudware_prv_ip'], mgt_ip: r.tags['cloudware_mgt_ip'], provider: 'azure', type: r.tags['cloudware_machine_type'] })
        end
      end
      @machines
    end

    def deploy(template, type, params, name)
      t = File.read(File.expand_path(File.join(__dir__, "../../templates/#{template}")))
      d = @client.model_classes.deployment.new
      d.properties = @client.model_classes.deployment_properties.new
      d.properties.template = JSON.parse(t)
      d.properties.mode = Resources::Models::DeploymentMode::Incremental
      d.properties.parameters = Hash[*params.map { |k, v| [k, { value: v }] }.flatten]
      debug_settings = @client.model_classes.debug_setting.new
      debug_settings.detail_level = 'requestContent, responseContent'
      d.properties.debug_setting = debug_settings
      log.info("Creating new deployment: #{type} #{name}")
      @client.deployments.create_or_update(name, type.to_s, d)
      operation_results = @client.deployment_operations.list(name, type.to_s)
      unless operation_results.nil?
        operation_results.each do |operation_result|
          until operation_result.properties.provisioning_state == 'Succeeded'
            sleep(1)
          end
        end
      end
      log.info("Deployment #{type} #{name} complete")
    end

    def destroy(name, domain)
      log.info("Destroying deployment #{name} #{domain}")
      @client.deployments.delete(domain, name)
    end

    def create_resource_group(region, id, name)
      params = @client.model_classes.resource_group.new.tap do |r|
        r.location = region
        r.tags = {
          cloudware_id: id,
          cloudware_domain: name,
          region: region
        }
      end
      log.info("Creating new resource group\nRegion: #{region}\nID: #{id}\n#{name}")
      @client.resource_groups.create_or_update(name, params)
    end

    def resource_groups
      groups = []
      log.info('Loading available resource groups')
      @client.resource_groups.list.each do |g|
        next if g.tags.nil?
        groups.push(g.tags['cloudware_domain']) unless g.tags['cloudware_domain'].nil?
      end
      groups
    end

    def resource_group_exists?(name)
      resource_groups.include? name
    end

    def log
      Cloudware.log
    end
  end
end
