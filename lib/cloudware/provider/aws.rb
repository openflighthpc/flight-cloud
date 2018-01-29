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

EC2 = Aws::EC2
CloudFormation = Aws::CloudFormation
Credentials = Aws::Credentials

module Cloudware
  class Aws
    include Utils

    def initialize(options = {})
      @options = options
      @region = options[:region] || 'eu-west-1'
    end

    def domains
      if @options[:domain] && @options[:region]
        find_domain
      elsif @options[:domain] && options[:region].nil?
        find_domain_by_name
      elsif @options[:domain].nil? && @options[:region]
        find_domains_by_region
      elsif @options[:domain].nil? && @options[:region].nil?
        find_domains
      end
    end

    private

    def find_domain(name = @options[:name], region = options[:region])
      vpcs.each do |vpc|
        next unless vpc.tags[:cloudware_domain] == name
        next unless vpc.tags[:cloudware_region] == region
        search.merge!(render_domain_info(vpc))
      end
      puts search
    end

    def find_domains
      vpcs.each do |vpc|
        search.merge!(render_domain_info(vpc))
      end
      search
    end

    def find_domain_by_name(name = @options[:domain])
      vpcs.each do |vpc|
        next unless vpc.tags[:cloudware_domain] == name
        search.merge!(render_domain_info(vpc))
      end
      search
    end

    def find_domain_by_region(region = @options[:region])
      vpcs.each do |vpc|
        next unless vpc.tags[:cloudware_region] == region
        search.merge!(render_domain_info(vpc))
      end
      search
    end

    def credentials
      @credentials ||= Credentials.new(
        config.aws_access_key_id,
        config.aws_secret_access_key
      )
    end

    def cfn
      @cfn ||= CloudFormation::Client.new(region: @region, credentials: credentials)
    end

    def ec2(region = @options[:region] || 'eu-west-1')
      @ec2 ||= EC2::Client.new(region: region, credentials: credentials)
    end

    def regions
      @regions ||= begin
        @regions = []
        ec2.describe_regions.regions.each do |region|
          @regions.push(region.region_name)
        end
        @regions
      end
    end

    def vpcs
      @vpcs ||= ec2.describe_vpcs(filters: [{ name: 'tag-key', values: ['cloudware_id'] }]).vpcs
    end

    def render_domain_info(vpc)
      domain.merge!(render_domain_tags(vpc.tags))
      domain[:vpcid] = vpc.vpc_id
      domain
    end

    def render_domain_tags(tags)
      @tag_hash = {}
      tags.each do |t|
        @tag_hash[:domain] = t.value if t.key == 'cloudware_domain'
        @tag_hash[:id] = t.value if t.key == 'cloudware_id'
        @tag_hash[:networkcidr] = t.value if t.key == 'cloudware_network_cidr'
        @tag_hash[:mgtcidr] = t.value if t.key == 'cloudware_mgt_subnet_cidr'
        @tag_hash[:prvcidr] = t.value if t.key == 'cloudware_prv_subnet_cidr'
        @tag_hash[:region] = t.value if t.key == 'cloudware_region'
      end
      render_domain_tag_hash(@tag_hash)
    end

    def render_domain_tag_hash(hash)
      {
        hash[:domain].to_s => {
          id: hash[:id],
          networkcidr: hash[:networkcidr],
          mgtcidr: hash[:mgtcidr],
          prvcidr: hash[:prvcidr],
          region: hash[:region],
          provider: 'aws'
        }
      }
    end

    def domain
      @domain ||= {}
    end

    def search
      @search ||= {}
    end
  end
end
