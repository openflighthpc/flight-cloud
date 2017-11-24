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

module Cloudware
  class Domain
    attr_accessor :name
    attr_accessor :id
    attr_accessor :networkcidr
    attr_accessor :prvsubnetcidr
    attr_accessor :mgtsubnetcidr
    attr_accessor :region
    attr_accessor :provider
    # aws provider specific
    attr_accessor :prvsubnetid, :mgtsubnetid, :networkid

    def load_cloud
      case get_provider
      when 'aws'
        @cloud = Cloudware::Aws.new
      when 'azure'
        @cloud = Cloudware::Azure.new
      end
    end

    def create
      raise('Invalid parameters') unless valid_create?
      load_cloud
      @cloud.create_domain(@name, SecureRandom.uuid, @networkcidr,
                           @prvsubnetcidr, @mgtsubnetcidr, @region)
    end

    def list
      # @todo - once we have GCP/AWS providers, merge
      # all providers data into a single hash and return
      list = {}
      azure = Cloudware::Azure.new
      aws = Cloudware::Aws.new
      list.merge!(azure.domain_list)
      list.merge!(aws.domain_list)
      puts list
      list
    end

    def get_list
      get_list ||= list
    end

    def destroy
      @provider = provider
      load_cloud
      @cloud.destroy('domain', @name)
    end

    def fail_domain_exist
      raise('Domain does not exist')
    end

    def get_name
      get_list[@name][:cloudware_domain] if exists? || fail_domain_exist
    end

    def get_id
      get_list[@name][:cloudware_id] if exists?
    end

    def get_provider
      get_list[@name][:provider] if exists?
    end

    def get_networkcidr
      get_list[@name][:network_cidr] if exists?
    end

    def get_mgtsubnetcidr
      get_list[@name][:prv_subnet_cidr] if exists?
    end

    def get_prvsubnetcidr
      get_list[@name][:prv_subnet_cidr] if exists?
    end

    def get_mgtsubnetid
      get_list[@name][:mgt_subnet_id] if exists?
    end

    def get_prvsubnetid
      get_list[@name][:prv_subnet_id] if exists?
    end

    def get_networkid
      get_list[@name][:network_id] if exists?
    end

    def get_region
      get_list[@name][:region] if exists?
    end

    def valid_create?
      exists?
      valid_name?
      valid_provider?
    end

    def exists?
      get_list.include? @name
    end

    def valid_name?
      !@name.match(/\A[a-zA-Z0-9-]*\z/).nil?
    end

    def valid_provider?
      %w[aws azure gcp].include? @provider
    end
  end
end
