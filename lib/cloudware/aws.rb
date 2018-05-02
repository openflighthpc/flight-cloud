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
  class Aws2
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
      if valid_credentials?
        log.debug("[#{self.class}] Loading credentials from config file")
        credentials = Credentials.new(config.aws_access_key_id, config.aws_secret_access_key)
        @cfn = CloudFormation::Client.new(region: region, credentials: credentials)
        @ec2 = EC2::Client.new(region: region, credentials: credentials)
      else
        # Assume at this point we have environment variables or profiles available
        log.debug("[#{self.class}] Loading credentials from environment or profile")
        @cfn = CloudFormation::Client.new(region: region)
        @ec2 = EC2::Client.new(region: region)
      end
    end

    def valid_credentials?
      !config.aws_access_key_id.nil? || !config.aws_secret_access_key.nil?
    end

    def regions
      @regions ||= begin
                     @regions = []
                     @ec2.describe_regions.regions.each { |r| @regions.push(r.region_name) }
                     @regions
                   end
    end

    # TOneverDO - tidy this
    def domains
      @domains ||= begin
                     log.debug("[#{self.class}] Scanning regions for available domains")
                     @domains = {}
                     regions.each do |r|
                       load_config(r)
                       log.info("[#{self.class}] Loading VPCs for region #{r}")
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
                         log.info("[#{self.class}] Loading subnets for VPC #{v.vpc_id}")
                         subnet_list = @ec2.describe_subnets(filters: [{ name: 'vpc-id', values: [v.vpc_id] }])
                         subnet_list.subnets.each do |s|
                           s.tags.each do |t|
                             @prv_subnet_id = s.subnet_id if t.key == "cloudware_#{@domain}_prv_subnet_id"
                             @mgt_subnet_id = s.subnet_id if t.key == "cloudware_#{@domain}_mgt_subnet_id"
                           end
                         end
                         log.info("[#{self.class}] Detected domain #{@domain} in region #{@region}")
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
                        log.info("[#{self.class}] Scanning instances in region #{r}")
                        
                        # Find failed machines in CloudFormation [in state ROLLBACK*]
                        @cfn.describe_stacks.stacks.each do |test|
                          next if ! test.stack_status.include?('ROLLBACK')
                          if test.parameters[0]
                            @state = 'failed'
                            @extip = 'N/A'
                            @name = test.stack_name
                            @instance_id = 'N/A'
                            test.parameters.each_with_index do |val, index|
                              @type = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'vmType'
                              @domain = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'cloudwareDomain'
                              @id = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'cloudwareId'
                              @role = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'vmRole'
                              @prvip = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'prvIp'
                              @mgtip = val.to_h[:parameter_value] if val.to_h[:parameter_key] == 'mgtIp'
                            end
                            log.info("[#{self.class}] Detected machine #{@name} in domain #{@domain}")
                            @machines.merge!("#{@domain}-#{@name}" => {
                                               name: @name, domain: @domain, state: @state,
                                               id: @id, type: @type, role: @role, mgt_ip: @mgtip,
                                               prv_ip: @prvip, ext_ip: @extip, provider: 'aws', instance_id: @instance_id
                                             })
                          end
                        end

                        # Find machines in ec2
                        @ec2.describe_instances(filters: [{ name: 'tag-key', values: ['cloudware_id'] }]).reservations.each do |reservation|
                          reservation.instances.each do |instance|
                            next if instance.state.name == 'terminated'
                            @state = instance.state.name
                            @extip = instance.public_ip_address || @extip = 'N/A'
                            @type = instance.instance_type
                            @instance_id = instance.instance_id
                            instance.tags.each do |tag|
                              @domain = tag.value if tag.key == 'cloudware_domain'
                              @id = tag.value if tag.key == 'cloudware_id'
                              @role = tag.value if tag.key == 'cloudware_machine_role'
                              @prvip = tag.value if tag.key == 'cloudware_prv_subnet_ip'
                              @mgtip = tag.value if tag.key == 'cloudware_mgt_subnet_ip'
                              @name = tag.value if tag.key == 'cloudware_machine_name'
                              @flavour = tag.value if tag.key == 'cloudware_machine_flavour'
                            end
                            log.info("[#{self.class}] Detected machine #{@name} in domain #{@domain}")
                            @machines.merge!("#{@domain}-#{@name}" => {
                                               name: @name, domain: @domain, state: @state,
                                               id: @id, type: @type, role: @role, mgt_ip: @mgtip,
                                               prv_ip: @prvip, ext_ip: @extip, provider: 'aws', instance_id: @instance_id
                                             })
                          end
                        end
                      end
                      log.info("[#{self.class}] Found machines:\n#{@machines}")
                      @machines
                    end
    end

    def machine_info(name, domain)
      @machine_info = {}
      regions.each do |r|
        load_config(r)
        @ec2.describe_instances(filters: [
                                  { name: 'tag:cloudware_domain', values: [domain.to_s] },
                                  { name: 'tag:cloudware_machine_name', values: [name.to_s] }
                                ]).reservations.each do |reservation|
          reservation.instances.each do |instance|
            @instance_id = instance.instance_id
            @state = instance.state.name
            @region = r
          end
        end
      end
      @machine_info.merge!(instance_id: @instance_id, state: @state, region: @region)
    end

    def machine_power_on(name, domain)
      log.info("#{self.class} Attempting to power on #{name} in #{domain}")
      load_config(machine_info(name, domain)[:region])
      @ec2.start_instances(instance_ids: [machine_info(name, domain)[:instance_id]])
    end

    def machine_power_off(name, domain)
      log.info("#{self.class} Attempting to power off #{name} in #{domain} - #{@region}")
      load_config(machine_info(name, domain)[:region])
      @ec2.stop_instances(instance_ids: [machine_info(name, domain)[:instance_id]])
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
      begin
        log.info("[#{self.class}] Deploying new stack\nName: #{name}\nTemplate: #{tpl_file}\nParams: #{params}")
        @cfn.create_stack stack_name: name, template_body: render_template(tpl_file), parameters: params
        log.info("[#{self.class}] Deployment for #{name} finished, waiting for deployment to reach complete")
        @cfn.wait_until :stack_create_complete, stack_name: name
        log.info("[#{self.class}] Deployment for #{name} reached complete status")
      # Catch errors and hand it up the stack for `cli.rb` to handle
      rescue CloudFormation::Errors::ServiceError, Aws::Waiters::Errors::FailureStateError => error
        raise error.message
      end
    end

    def destroy(name, domain)
      d = Cloudware::Domain.new
      d.name = domain
      load_config(d.get_item('region'))
      begin
        log.info("[#{self.class}] Beginning stack deletion for stack #{name}-#{domain}")
        @cfn.delete_stack stack_name: "#{domain}-#{name}"
        log.info("[#{self.class}] Waiting until stack reaches deleted status: #{name}-#{domain}")
        @cfn.wait_until :stack_delete_complete, stack_name: "#{domain}-#{name}"
        log.info("[#{self.class}] Stack reached deleted status: #{domain}-#{name}")
      # Catch errors and hand it up the stack for `cli.rb` to handle
      rescue CloudFormation::Errors::ServiceError => error
        raise error.message
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
