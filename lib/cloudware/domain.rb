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
# You should have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================
require 'securerandom'
require 'ipaddr'

module Cloudware
  class Domain
    attr_accessor :name
    attr_accessor :id
    attr_accessor :networkcidr
    attr_accessor :prisubnetcidr
    attr_accessor :region
    attr_accessor :provider
    # aws provider specific
    attr_accessor :prisubnetid, :networkid

    def initialize
      @items = {}
    end

    def load_cloud
      case @provider
      when 'aws'
        @cloud = Cloudware::Aws2.new
      when 'azure'
        @cloud = Cloudware::Azure.new
      else
        @aws = Cloudware::Aws2.new
        @azure = Cloudware::Azure.new
      end
    end

    def describe
      @describe ||= begin
                    domain = Struct.new :name, :region, :provider, :networkcidr, :prisubnetcidr
                    @describe = domain.new(get_item('domain'), get_item('region'), get_item('provider'), get_item('network_cidr'), get_item('pri_subnet_cidr'))
                  end
    end

    def create
      load_cloud
      @cloud.create_domain(@name, SecureRandom.uuid, @networkcidr,
                           @prisubnetcidr, @region)
    end

    def _load_domains(provider)
      case provider
      when 'aws'
        cloud = Cloudware::Aws2.new
      when 'azure'
        cloud = Cloudware::Azure.new
      else
        raise "Provider #{provider} doesn't exist"
      end
      log.debug("[#{self.class}] Loaded machines from #{provider}:\n#{cloud.domains}")
      cloud.domains
    end

    def list
      @list ||= begin
                  @list = {}
                  Cloudware.config.providers.each do |a|
                    @list.merge!(_load_domains(a))
                  end
                  log.debug("[#{self.class}] Detected domains:\n#{@list}")
                  @list
                end
    end

    def domains_by_region(region)
      @domains_by_region ||= begin
                               load_cloud
                               @domains_by_region = @cloud.domains
                               @domains_by_region.each do |k, v|
                                 k.delete(k) if v[:region] != region
                               end
                               @domains_by_region
                             end
    end

    def destroy
      raise('Unable to destroy domain with active machines') if has_machines?
      @provider = get_item('provider')
      load_cloud
      @cloud.destroy('domain', @name)
    end

    def get_item(item)
      @items[item] = begin
                       log.debug("[#{self.class}] Loading #{item} from API")
                       list[@name][item.to_sym]
                     end
    end

    # TODO: What is this suppose to do?
    def has_machines?
      false
    end

    def exists?
      list.include? @name || false
    end

    def valid_name?
      !@name.match(/\A[a-zA-Z0-9-]*\z/).nil?
    end

    def valid_provider?
      %w[aws azure gcp].include? @provider
    end

    def log
      Cloudware.log
    end

    def valid_cidr?(cidr)
      IPAddr.new(cidr).ipv4?
    end

    def is_valid_subnet_cidr?(network, subnet)
      network_cidr = IPAddr.new(network)
      subnet_cidr = IPAddr.new(subnet)
      network_cidr.include?(subnet_cidr)
    end
  end
end
