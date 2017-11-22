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

    def load_config(region)
      @cfn = CloudFormation::Client.new(region: region)
      @ec2 = EC2::Client.new(region: region)
    end

    def regions
      regions = []
      @ec2.describe_regions.regions.each do |r|
        regions.push(r.region_name)
      end
      regions
    end

    # Return any subnets belonging to a given VPC
    def subnet_list(vpc_id)
      @ec2.describe_subnets(filters: [
                              {
                                name: 'vpc-id',
                                values: [vpc_id]
                              }
                            ])
    end

    # TOneverDO - tidy this
    def domains
      domains = {}
      vpc_list = @ec2.describe_vpcs
      regions.each do |r|
        load_config(r)
        vpc_list = @ec2.describe_vpcs(filters: [{ name: 'tag-key', values: ['cloudware_id'] }])
        vpc_list.vpcs.each do |v|
          v.tags.each do |t|
            @cloudware_domain = t.value if t.key == 'cloudware_domain'
            @cloudware_id = t.value if t.key == 'cloudware_id'
            @network_cidr = t.value if t.key == 'cloudware_network_cidr'
            @prv_subnet_cidr = t.value if t.key == 'cloudware_prv_subnet_cidr'
            @mgt_subnet_cidr = t.value if t.key == 'cloudware_mgt_subnet_cidr'
            @region = r
          end
          subnet_list = @ec2.describe_subnets(filters: [{ name: 'vpc-id', values: [v.vpc_id] }])
          subnet_list.subnets.each do |s|
            s.tags.each do |t|
              @prv_subnet_id = t.value if t.key == "cloudware_#{@cloudware_domain}_prv_subnet_id"
              @mgt_subnet_id = t.value if t.key == "cloudware_#{@cloudware_domain}_mgt_subnet_id"
            end
          end
          domains.merge!(@cloudware_domain => { cloudware_domain: @cloudware_domain,
                                                cloudware_id: @cloudware_id, network_cidr: @network_cidr,
                                                prv_subnet_cidr: @prv_subnet_cidr, mgt_subnet_cidr: @mgt_subnet_cidr,
                                                prv_subnet_id: @prv_subnet_id, mgt_subnet_id: @mgt_subnet_id,
                                                region: @region, provider: 'aws' })
        end
      end
      domains
    end

    def create_domain(name, id, networkcidr, prvsubnetcidr, mgtsubnetcidr, region)
      load_config(region)
      template = 'aws-network-base.yml'
      params = [
        { parameter_key: 'cloudwareDomain', parameter_value: name },
        { parameter_key: 'cloudwareId', parameter_value: id },
        { parameter_key: 'networkCidr', parameter_value: networkcidr },
        { parameter_key: 'prvSubnetCidr', parameter_value: prvsubnetcidr },
        { parameter_key: 'mgtSubnetCidr', parameter_value: mgtsubnetcidr }
      ]
      deploy(name, template, params)
    end

    def create_machine(name, domain, id, prvip, mgtip, type, size, region)
      load_config(region)
      template = "aws-machine-#{type}.yml"
      params = [
        { parameter_key: 'cloudwareDomain', parameter_value: domain },
        { parameter_key: 'cloudwareId', parameter_value: id },
        { parameter_key: 'prvIp', parameter_value: prvip },
        { parameter_key: 'mgtIp', parameter_value: mgtip },
        { parameter_key: 'vmType', parameter_value: type },
        { parameter_key: 'vmSize', parameter_value: size }
      ]
      deploy(name, template, params)
    end

    def deploy(name, template, params)
      template = File.read(File.expand_path(File.join(__dir__, "../../templates/#{template}")))
      @cfn.create_stack stack_name: name, template_body: template, parameters: params
      @cfn.wait_until :stack_create_complete, stack_name: name
    end

    def destroy(_type, name, region)
      load_config(region)
      @cfn.delete_stack stack_name: name
      @cfn.wait_until :stack_delete_complete, stack_name: name
    end
  end
end
