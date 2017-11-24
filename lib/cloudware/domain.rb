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
      case @provider
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
      list
    end

    def destroy
      @provider = provider
      load_cloud
      @cloud.destroy('domain', @name, region)
    end

    def name
      raise('Invalid name') unless valid_name? || @name
    end

    def id
      list[@name][:cloudware_id] if exists? || @id
    end

    def provider
      list[@name][:provider] if exists? || @provider
    end

    def networkcidr
      list[@name][:network_cidr] if exists? || @networkcidr
    end

    def mgtsubnetcidr
      list[@name][:prv_subnet_cidr] if exists? || @mgtsubnetcidr
    end

    def prvsubnetcidr
      list[@name][:prv_subnet_cidr] if exists? || @prvsubnetcidr
    end

    def mgtsubnetid
      list[@name][:mgt_subnet_id] if exists? || @mgtsubnetid
    end

    def prvsubnetid
      list[@name][:prv_subnet_id] if exists? || @prvsubnetid
    end

    def networkid
      list[@name][:network_id] if exists? || @networkid
    end

    def region
      list[@name][:region] if exists? || @region
    end

    def valid_create?
      exists?
      valid_name?
      valid_provider?
    end

    def exists?
      list.include? @name
    end

    def valid_name?
      !@name.match(/\A[a-zA-Z0-9-]*\z/).nil?
    end

    def valid_provider?
      %w[aws azure gcp].include? @provider
    end
  end
end
