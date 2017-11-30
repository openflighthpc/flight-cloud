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
require 'aws-sdk-cloudformation'
require 'aws-sdk-ec2'

CloudFormation = Aws::CloudFormation
EC2 = Aws::EC2
Credentials = Aws::Credentials

module Cloudware
  class Aws
    attr_accessor :cloudware_domain
    attr_accessor :cloudware_id
    attr_accessor :network_cidr
    attr_accessor :prv_subnet_cidr
    attr_accessor :mgt_subnet_cidr
    attr_accessor :prv_subnet_id
    attr_accessor :mgt_subnet_id
    attr_accessor :region

    def initialize
      # Load a default region, which we'll override later
      @region = 'us-east-1'
      load_config(region)
    end

    def config
      Cloudware.config
    end

    def load_config(region)
      unless config.aws_access_key_id.nil? && config.aws_secret_access_key.nil?
        Credentials.new(config.aws_access_key_id, config.aws_secret_access_key)
      end
      @cfn = CloudFormation::Client.new(region: region)
      @ec2 = EC2::Client.new(region: region)
    end

    def regions
      @regions ||= begin
                     log.warn('Loading available regions from API')
                     @regions = []
                     @ec2.describe_regions.regions.each do |r|
                       @regions.push(r.region_name)
                     end
                     @regions
                   end
    end

    # TOneverDO - tidy this
    def domains
      @domains ||= begin
                     log.warn('Loading domains from API')
                     @domains = {}
                     regions.each do |r|
                       load_config(r)
                       log.info("Loading VPCs for region #{r}")
                       vpc_list = @ec2.describe_vpcs(filters: [{ name: 'tag-key', values: ['cloudware_id'] }])
                       vpc_list.vpcs.each do |v|
                         v.tags.each do |t|
                           @domain = t.value if t.key == 'cloudware_domain'
                           @id = t.value if t.key == 'cloudware_id'
                           @network_cidr = t.value if t.key == 'cloudware_network_cidr'
                           @prv_subnet_cidr = t.value if t.key == 'cloudware_prv_subnet_cidr'
                           @mgt_subnet_cidr = t.value if t.key == 'cloudware_mgt_subnet_cidr'
                           @networkid = v.vpc_id
                           @region = r
                         end
                         log.info("Loading subnets for VPC #{v.vpc_id} in region #{r}")
                         subnet_list = @ec2.describe_subnets(filters: [{ name: 'vpc-id', values: [v.vpc_id] }])
                         subnet_list.subnets.each do |s|
                           s.tags.each do |t|
                             @prv_subnet_id = s.subnet_id if t.key == "cloudware_#{@domain}_prv_subnet_id"
                             @mgt_subnet_id = s.subnet_id if t.key == "cloudware_#{@domain}_mgt_subnet_id"
                           end
                         end
                         @domains.merge!(@domain => {
                                           domain: @domain, id: @id, network_cidr: @network_cidr,
                                           prv_subnet_cidr: @prv_subnet_cidr, mgt_subnet_cidr: @mgt_subnet_cidr,
                                           prv_subnet_id: @prv_subnet_id, mgt_subnet_id: @mgt_subnet_id,
                                           region: @region, provider: 'aws', network_id: @networkid
                                         })
                       end
                     end
                     @domains
                   end
    end

    def machines
      @machines ||= begin
                      @machines = {}
                      regions.each do |r|
                        load_config(r)
                        log.info("Loading instances in region #{r}")
                        @ec2.describe_instances(filters: [{ name: 'tag-key', values: ['cloudware_id'] }]).reservations.each do |reservation|
                          reservation.instances.each do |instance|
                            next if instance.state.name == 'terminated'
                            @state = instance.state.name
                            @extip = instance.public_ip_address || @extip = 'N/A'
                            @type = instance.instance_type
                            instance.tags.each do |tag|
                              @domain = tag.value if tag.key == 'cloudware_domain'
                              @id = tag.value if tag.key == 'cloudware_id'
                              @role = tag.value if tag.key == 'cloudware_machine_role'
                              @prvip = tag.value if tag.key == 'cloudware_prv_subnet_ip'
                              @mgtip = tag.value if tag.key == 'cloudware_mgt_subnet_ip'
                              @name = tag.value if tag.key == 'cloudware_machine_name'
                              @flavour = tag.value if tag.key == 'cloudware_machine_flavour'
                            end
                            log.info("Detected machine #{@name} in domain #{@domain}")
                            @machines.merge!(@name => {
                                               name: @name, domain: @domain, state: @state,
                                               id: @id, type: @type, role: @role, mgt_ip: @mgtip,
                                               prv_ip: @prvip, ext_ip: @extip, provider: 'aws'
                                             })
                          end
                        end
                      end
                      @machines
                    end
    end

    def create_domain(name, id, networkcidr, prvsubnetcidr, mgtsubnetcidr, region)
      load_config(region)
      template = 'domain.yml'
      params = [
        { parameter_key: 'cloudwareDomain', parameter_value: name },
        { parameter_key: 'cloudwareId', parameter_value: id },
        { parameter_key: 'networkCidr', parameter_value: networkcidr },
        { parameter_key: 'prvSubnetCidr', parameter_value: prvsubnetcidr },
        { parameter_key: 'mgtSubnetCidr', parameter_value: mgtsubnetcidr }
      ]
      deploy("#{name}-domain", template, params)
    end

    def create_machine(name, domain, id, prvip, mgtip, role, type, region, flavour)
      d = Cloudware::Domain.new
      d.name = domain
      load_config(region)
      template = "machine-#{role}.yml"
      params = [
        { parameter_key: 'cloudwareDomain', parameter_value: domain },
        { parameter_key: 'cloudwareId', parameter_value: id },
        { parameter_key: 'prvIp', parameter_value: prvip },
        { parameter_key: 'mgtIp', parameter_value: mgtip },
        { parameter_key: 'vmRole', parameter_value: role },
        { parameter_key: 'vmType', parameter_value: type },
        { parameter_key: 'vmName', parameter_value: name },
        { parameter_key: 'networkId', parameter_value: d.get_item('network_id') },
        { parameter_key: 'prvSubnetId', parameter_value: d.get_item('prv_subnet_id') },
        { parameter_key: 'mgtSubnetId', parameter_value: d.get_item('mgt_subnet_id') },
        { parameter_key: 'prvSubnetCidr', parameter_value: d.get_item('prv_subnet_cidr') },
        { parameter_key: 'mgtSubnetCidr', parameter_value: d.get_item('mgt_subnet_cidr') },
        { parameter_key: 'vmFlavour', parameter_value: flavour }
      ]
      deploy("#{domain}-#{name}", template, params)
    end

    def deploy(name, tpl_file, params)
      log.info("Deploying new stack\nName: #{name}\nTemplate: #{tpl_file}\nParams: #{params}")
      @cfn.create_stack stack_name: name, template_body: render_template(tpl_file), parameters: params
      log.info("Deployment for #{name} finished, waiting for deployment to reach complete")
      @cfn.wait_until :stack_create_complete, stack_name: name
      log.info("Deployment for #{name} reached complete status")
    end

    def destroy(name, domain)
      d = Cloudware::Domain.new
      d.name = domain
      load_config(d.get_item('region'))
      begin
        log.info("Beginning stack deletion for stack #{name}-#{domain}")
        @cfn.delete_stack stack_name: "#{domain}-#{name}"
        log.info("Waiting until stack reaches deleted status: #{name}-#{domain}")
        @cfn.wait_until :stack_delete_complete, stack_name: "#{domain}-#{name}"
        log.info("Stack reached deleted status: #{domain}-#{name}")
      rescue CloudFormation::Errors::ServiceError
      end
    end

    def render_template(template)
      File.read(File.expand_path(File.join(__dir__, "../../providers/aws/templates/#{template}")))
    end

    def log
      Cloudware.log
    end
  end
end
