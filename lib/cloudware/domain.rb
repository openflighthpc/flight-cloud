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

    def load_cloud
      case @provider
      when 'azure'
        @cloud = Cloudware::Azure.new
      end
    end

    def create
      abort('Invalid domain name') unless validate_name
      load_cloud
      @cloud.create_domain(@name, SecureRandom.uuid, @networkcidr,
             @prvsubnetcidr, @mgtsubnetcidr, @region)
    end

    def list
      # @todo - once we have GCP/AWS providers, merge
      # all providers data into a single hash and return
      list = {}
      azure = Cloudware::Azure.new
      list.merge!(azure.list_domains)
      list
    end

    def destroy
      # Provide hardcoded 'domain' name to `provider.destroy`
      # the domain deployment is always labelled 'domain'
      @cloud.destroy('domain', @domain)
    end

    def name
      return false unless validate_name
      @name
    end

    def provider 
      unless validate_provider
        return false
      else
        @provider
      end
    end

    def get_provider
      list[@name][:provider]
    end

    def get_id
      list[@name][:cloudware_id]
    end

    def validate_name
      !@name.match(/\A[a-zA-Z0-9]*\z/).nil?
    end

    def validate_provider
      ['aws', 'azure', 'gcp'].include? @provider      
    end
  end
end
