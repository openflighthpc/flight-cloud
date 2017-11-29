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
require 'azure_mgmt_compute'
require 'azure_mgmt_network'

Resources = Azure::Resources::Profiles::Latest::Mgmt
Compute = Azure::Compute::Profiles::Latest::Mgmt
Network = Azure::Network::Profiles::Latest::Mgmt

module Cloudware
  class Azure
    def initialize
      subscription_id = config.azure_subscription_id
      provider = MsRestAzure::ApplicationTokenProvider.new(
        config.azure_tenant_id,
        config.azure_client_id,
        config.azure_client_secret
      )
      credentials = MsRest::TokenCredentials.new(provider)
      options = {
        credentials: credentials,
        subscription_id: subscription_id
      }
      log.info('Loading Azure client')
      @resources_client = Resources::Client.new(options)
      @compute_client = Compute::Client.new(options)
      @network_client = Network::Client.new(options)
    end

    def config
      Cloudware.config
    end

    def create_domain(name, id, networkcidr, prvsubnetcidr, mgtsubnetcidr, region)
      abort('Domain already exists') if resource_group_exists?(name)
      create_resource_group(region, id, name)
      t = 'domain.json'
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
      @domains ||= begin
                     @domains = {}
                     resource_groups.each do |g|
                       log.info("Listing available resources in group #{g}")
                       resources = @resources_client.resources.list_by_resource_group(g)
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
    end

    def create_machine(name, domain, id, prvip, mgtip, type, size, _region)
      t = "machine-#{type}.json"
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
      @machines ||= begin
                      @machines = {}
                      resource_groups.each do |g|
                        resources = @resources_client.resources.list_by_resource_group(g)
                        resources.each do |r|
                          next unless r.tags['cloudware_resource_type'] == 'machine'
                          next unless r.type == 'Microsoft.Compute/virtualMachines'
                          log.info("Deteched machine #{r.tags['cloudware_machine_name']} in domain #{r.tags['cloudware_domain']}")
                          if r.tags['cloudware_machine_role'] == 'master'
                            ext_ip = get_external_ip(r.tags['cloudware_domain'], r.tags['cloudware_machine_name'])
                          end
                          @machines.merge!(r.tags['cloudware_machine_name'] => {
                                             domain: r.tags['cloudware_domain'],
                                             role: r.tags['cloudware_machine_role'],
                                             prv_ip: r.tags['cloudware_prv_ip'],
                                             mgt_ip: r.tags['cloudware_mgt_ip'],
                                             ext_ip: ext_ip,
                                             provider: 'azure',
                                             type: r.tags['cloudware_machine_type'],
                                             state: get_instance_state(r.tags['cloudware_domain'], r.tags['cloudware_machine_name'])
                                           })
                        end
                      end
                      @machines
                    end
    end

    def deploy(template, type, params, name)
      t = File.read(File.expand_path(File.join(__dir__, "../../providers/azure/templates/#{template}")))
      d = @resources_client.model_classes.deployment.new
      d.properties = @resources_client.model_classes.deployment_properties.new
      d.properties.template = JSON.parse(t)
      d.properties.mode = Resources::Models::DeploymentMode::Incremental
      d.properties.parameters = Hash[*params.map { |k, v| [k, { value: v }] }.flatten]
      debug_settings = @resources_client.model_classes.debug_setting.new
      debug_settings.detail_level = 'requestContent, responseContent'
      d.properties.debug_setting = debug_settings
      log.info("Creating new deployment: #{type} #{name}")
      @resources_client.deployments.create_or_update(name, type.to_s, d)
      operation_results = @resources_client.deployment_operations.list(name, type.to_s)
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
      if name == 'domain'
        destroy_resource_group(domain)
      else
        destroy_deployment(domain, name)
        destroy_instance(domain, name)
        destroy_network_interfaces(domain, name)
        destroy_security_groups(domain, name)
        desotry_public_ip_address(domain, name)
      end
      @resources_client.deployments.delete(domain, name)
    end

    def destroy_instance(domain, name)
      log.info("Destroying instance #{name} in domain #{domain}")
      @compute_client.virtual_machines.delete(domain, name)
    end

    def destroy_network_interfaces(domain, name)
      log.info("Destroying prv interface for instance #{name} in domain #{domain}")
      @network_client.network_interfaces.delete(domain, "#{name}prv")
      log.info("Destroyed prv interface for instance #{name} in domain #{domain}")
      log.info("Destroying mgt interface for instance #{name} in domain #{domain}")
      @network_client.network_interfaces.delete(domain, "#{name}mgt")
      log.info("Destroyed mgt interface for instance #{name} in domain #{domain}")
    end

    def destroy_security_groups(domain, name)
      log.info("Destroying network security group #{name} in domain #{domain}")
      @network_client.network_security_groups.delete(domain, name)
      log.info("Destroyed network security group #{name} in domain #{domain}")
    end

    def destroy_public_ip_address(domain, name)
      log.info("Destroying public IP address for instance #{name} in domain #{domain}")
      @network_client.public_ipaddresses.delete(domain, name)
    end

    def destroy_deployment(domain, name)
      log.info("Destroying deployment #{name} in resource group #{domain}")
      @resources_client.deployments.delete(domain, name)
      log.info("Finished destroying deployment #{name} in resource group #{domain}")
    end

    def destroy_resource_group(domain)
      log.info("Destroying resource group #{domain}")
      @resources_client.resource_groups.delete(domain)
      log.info("Resource group #{domain} destroyed")
    end

    def get_external_ip(domain, name)
      @network_client.public_ipaddresses.get(domain, name).ip_address
    end

    def get_instance_state(domain, name)
      if instance_running?(domain, name)
        'running'
      elsif instance_stopped?(domain, name)
        'stopped'
      end
    end

    def instance_running?(domain, name)
      log.info("Querying machine #{name} in domain #{domain} running status")
      !@compute_client.virtual_machines.instance_view(domain, name).statuses.find { |s| s.code =~ /PowerState\/running/ }.nil?
    end

    def instance_stopped?(domain, name)
      log.info("Querying machine #{name} in domain #{domain} running status")
      !@compute_client.virtual_machines.instance_view(domain, name).statuses.find { |s| s.code =~ /PowerState\/stopped/ }.nil?
    end

    def create_resource_group(region, id, name)
      params = @resources_client.model_classes.resource_group.new.tap do |r|
        r.location = region
        r.tags = {
          cloudware_id: id,
          cloudware_domain: name,
          region: region
        }
      end
      log.info("Creating new resource group\nRegion: #{region}\nID: #{id}\n#{name}")
      @resources_client.resource_groups.create_or_update(name, params)
    end

    def resource_groups
      @resource_groups ||= begin
                    @resource_groups = []
                    log.warn('Loading resource groups from API')
                    @resources_client.resource_groups.list.each do |g|
                      next if g.tags.nil?
                      @resource_groups.push(g.tags['cloudware_domain']) unless g.tags['cloudware_domain'].nil?
                    end
                    @resource_groups
                  end
    end

    def resource_group_exists?(name)
      resource_groups.include? name
    end

    def log
      Cloudware.log
    end
  end
end
