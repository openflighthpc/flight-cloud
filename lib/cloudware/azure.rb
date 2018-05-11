# frozen_string_literal: true

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
      log.debug("[#{self.class}] Loading Resources client")
      @resources_client = Resources::Client.new(options)
      log.debug("[#{self.class}] Loading Compute client")
      @compute_client = Compute::Client.new(options)
      log.debug("[#{self.class}] Loading Network client")
      @network_client = Network::Client.new(options)
    end

    def options
      @options ||= begin
        provider = MsRestAzure::ApplicationTokenProvider.new(
          config.azure.tenant_id,
          config.azure.client_id,
          config.azure.client_secret
        )
        credentials = MsRest::TokenCredentials.new(provider)
        @options = {
          credentials: credentials,
          subscription_id: config.azure.subscription_id.to_s,
          tenant_id: config.azure.tenant_id.to_s,
          client_id: config.azure.client_id.to_s,
          client_secret: config.azure.client_secret.to_s,
        }
        @options
      end
    end

    def config
      Cloudware.config
    end

    def log
      Cloudware.log
    end

    def create_domain(name, id, networkcidr, prvsubnetcidr, region)
      raise('Domain already exists') if resource_group_exists?(name)
      create_resource_group(region, id, name)
      params = {
        cloudwareDomain: name,
        cloudwareId: id,
        networkCIDR: networkcidr,
        prvSubnetCIDR: prvsubnetcidr,
      }
      deploy(name, 'domain', 'domain', params)
    end

    def domains
      @domains ||= begin
        @domains = {}
        resource_groups.each do |g|
          log.info("[#{self.class}] Listing available resources in group #{g}")
          resources = @resources_client.resources.list_by_resource_group(g)
          resources.each do |r|
            next unless r.tags['cloudware_resource_type'] == 'domain'
            next unless r.type == 'Microsoft.Network/virtualNetworks'
            log.info("[#{self.class}] Detected domain #{r.tags['cloudware_domain']} in region #{r.tags['cloudware_domain_region']}")
            @domains.merge!(r.tags['cloudware_domain'] => {
                              domain: r.tags['cloudware_domain'],
                              id: r.tags['cloudware_id'],
                              network_cidr: r.tags['cloudware_network_cidr'],
                              prv_subnet_cidr: r.tags['cloudware_prv_subnet_cidr'],
                              provider: 'azure',
                              region: r.tags['cloudware_domain_region'],
                            })
          end
        end
        @domains
      end
    end

    def create_machine(name, domain, id, prvip, type, size, region, flavour)
      rg = "#{domain}-#{name}"
      abort('Machine already exists') if resource_group_exists?(rg)
      create_resource_group(region, id, rg)
      params = {
        cloudwareDomain: domain,
        cloudwareId: id,
        vmName: name,
        vmType: size,
        prvSubnetIp: prvip,
        vmFlavour: flavour,
      }
      deploy(rg, name, "machine-#{type}", params)
    end

    def machines
      @machines ||= begin
        @machines = {}
        resource_groups.each do |g|
          resources = @resources_client.resources.list_by_resource_group(g)
          resources.each do |r|
            next unless r.tags
            next unless r.tags['cloudware_resource_type'] == 'machine'
            next unless r.type == 'Microsoft.Compute/virtualMachines'
            log.info("[#{self.class}] Detected machine #{r.tags['cloudware_machine_name']} in domain #{r.tags['cloudware_domain']}")
            if r.tags['cloudware_machine_role'] == 'master'
              ext_ip = get_external_ip(r.tags['cloudware_domain'], r.tags['cloudware_machine_name'])
            end
            @machines.merge!("#{r.tags['cloudware_domain']}-#{r.tags['cloudware_machine_name']}" => {
                               name: r.tags['cloudware_machine_name'],
                               id: r.tags['cloudware_id'],
                               domain: r.tags['cloudware_domain'],
                               role: r.tags['cloudware_machine_role'],
                               prv_ip: r.tags['cloudware_prv_ip'],
                               ext_ip: ext_ip,
                               provider: 'azure',
                               type: r.tags['cloudware_machine_type'],
                               flavour: r.tags['cloudware_machine_flavour'],
                               state: machine_state(r.tags['cloudware_machine_name'], r.tags['cloudware_domain']),
                             })
          end
        end
        @machines
      end
    end

    def machine_state(name, domain)
      state = @compute_client.virtual_machines.instance_view("#{domain}-#{name}", name)
      return 'running' unless state.statuses.find { |s| s.code =~ /PowerState\/running/ }.nil?
      return 'stopped' unless state.statuses.find { |s| s.code =~ /PowerState\/stopped/ }.nil?
    end

    def machine_power_on(name, domain)
      log.info("#{self.class} Attempting to power off #{name} in #{domain}")
      @compute_client.virtual_machines.start("#{domain}-#{name}", name)
    end

    def machine_power_off(name, domain)
      log.info("#{self.class} Attempting to power on #{name} in #{domain}")
      @compute_client.virtual_machines.power_off("#{domain}-#{name}", name)
    end

    def deploy(resource_group, name, type, params)
      deployment = @resources_client.model_classes.deployment.new
      deployment.properties = @resources_client.model_classes.deployment_properties.new
      deployment.properties.template = JSON.parse(render_template(type))
      deployment.properties.mode = Resources::Models::DeploymentMode::Incremental
      deployment.properties.parameters = render_params(params)
      debug_settings = @resources_client.model_classes.debug_setting.new
      debug_settings.detail_level = 'requestContent, responseContent'
      deployment.properties.debug_setting = debug_settings
      @resources_client.deployments.create_or_update(resource_group, name, deployment)
      @operation_results = @resources_client.deployment_operations.list(resource_group, name)
      wait_for_deployment_complete(resource_group, name)
    end

    def render_template(type)
      File.read(File.expand_path(File.join(__dir__, "../../providers/azure/templates/#{type}.json")))
    end

    def render_params(params)
      Hash[*params.map { |k, v| [k, { value: v }] }.flatten]
    end

    def wait_for_deployment_complete(resource_group, name)
      unless @operation_results.nil?
        log.info("[#{self.class}] Waiting for deployment #{name} in resource group #{resource_group} to finish")
        @operation_results.each do |r|
          sleep(1) until r.properties.provisioning_state == 'Succeeded'
        end
        log.info("[#{self.class}] Deployment #{name} in resource group #{resource_group} finished")
      end
    end

    def destroy(name, domain)
      rg = if name == 'domain'
             domain
           else
             "#{domain}-#{name}"
           end
      log.info("[#{self.class}] Destroying resource group #{rg}")
      @resources_client.resource_groups.delete(rg)
      log.info("[#{self.class}] Resource group #{rg} destroyed")
    end

    def get_external_ip(domain, name)
      @network_client.public_ipaddresses.get("#{domain}-#{name}", name).ip_address || 'N/A'
    end

    def create_resource_group(region, id, name)
      params = @resources_client.model_classes.resource_group.new.tap do |r|
        r.location = region
        r.tags = {
          cloudware_id: id,
          cloudware_domain: name,
          region: region,
        }
      end
      log.info("[#{self.class}] Creating new resource group\nRegion: #{region}\nID: #{id}\n#{name}")
      @resources_client.resource_groups.create_or_update(name, params)
    end

    def resource_groups
      @resource_groups ||= begin
        @resource_groups = []
        log.warn("[#{self.class}] Loading resource groups from API")
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
  end
end
