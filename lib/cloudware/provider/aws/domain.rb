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
module Cloudware
  class Aws
    module Domain
      include Utils

      def domains
        if @options[:domain] && @options[:region]
          find_domain
        elsif @options[:domain].nil? && @options[:region].nil?
          find_domains
        elsif @options[:domain] && @options[:region].nil?
          find_domain_by_name
        elsif @options[:domain].nil? && @options[:region]
          find_domains_by_region
        end
      end

      private

      def find_domain(name = @options[:domain], region = @options[:region])
        vpcs.each do |vpc|
          vpc.tags.each do |t|
            next unless t.value == name && t.key == 'cloudware_domain'
            next unless t.value == region && t.key == 'cloudware_region'
            return render_domain_info(vpc)
          end
        end
      end

      def find_domains
        @search = {}
        regions.each do |region|
          vpcs(region).each do |vpc|
            vpc.tags.each do |t|
              @search.merge!(render_domain_info(vpc)) 
            end
          end
        end
        return @search
      end

      def find_domain_by_name(name = @options[:domain])
        regions.each do |region|
          vpcs.each do |vpc|
            vpc.tags.each do |t|
              next unless t.value == name && t.key == 'cloudware_domain'
              return render_domain_info(vpc)
            end
          end
        end
      end

      def find_domains_by_region(region = @options[:region])
        @search = {}
        vpcs.each do |vpc|
          vpc.tags.each do |t|
            next unless t.value == region && t.key == 'cloudware_region'
            @search.merge!(render_domain_info(vpc))
          end
        end
        return @search
      end

      def render_domain_info(vpc)
        domain.merge!(render_domain_tags(vpc.tags, vpc.vpc_id))
        return domain
      end

      def render_domain_tags(tags, vpcid)
        @tag_hash = {}
        @tag_hash[:vpcid] = vpcid
        tags.each do |t|
          @tag_hash[:domain] = t.value if t.key == 'cloudware_domain'
          @tag_hash[:id] = t.value if t.key == 'cloudware_id'
          @tag_hash[:networkcidr] = t.value if t.key == 'cloudware_network_cidr'
          @tag_hash[:mgtcidr] = t.value if t.key == 'cloudware_mgt_subnet_cidr'
          @tag_hash[:prvcidr] = t.value if t.key == 'cloudware_prv_subnet_cidr'
          @tag_hash[:region] = t.value if t.key == 'cloudware_region'
        end
        puts log.public_methods
        log.info("Detected domain #{@tag_hash[:domain]}")
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
            vpcid: hash[:vpcid],
            provider: 'aws'
          }
        }
      end

      def vpcs(region = @options[:region])
        ec2(region).describe_vpcs(filters: [{ name: 'tag-key', values: ['cloudware_id'] }]).vpcs
      end

      def domain
        @domain ||= {}
      end

      def search
        @search ||= {}
      end
    end
  end
end
