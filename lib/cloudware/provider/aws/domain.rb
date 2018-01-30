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
      def domains
        find_domain
      end

      private

      def find_domain(name = @options[:domain], region = @options[:region])
        vpcs.each do |vpc|
          vpc.tags.each do |t|
            next unless t.value == name && t.key == 'cloudware_domain'
            return render_domain_info(vpc)
          end
        end
      end

      def render_domain_info(vpc)
        domain.merge!(render_domain_tags(vpc.tags))
        domain[:vpcid] = vpc.vpc_id
        return domain
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

      def vpcs
        @vpcs ||= ec2.describe_vpcs(filters: [{ name: 'tag-key', values: ['cloudware_id'] }]).vpcs
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
