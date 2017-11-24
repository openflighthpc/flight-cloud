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
  class Machine < Domain
    attr_accessor :name
    attr_accessor :domain
    attr_accessor :prvsubnetip
    attr_accessor :mgtsubnetip
    # type: Cloudware instance type, e.g. master,slave
    attr_accessor :type
    # size: Provider specific VM size
    attr_accessor :size

    def load_cloud
      @d = Cloudware::Domain.new
      @d.name = @domain
      p = @d.get_provider
      case @d.get_provider
      when 'azure'
        @cloud = Cloudware::Azure.new
      when 'aws'
        @cloud = Cloudware::Aws.new
      end
    end

    def create
      raise('Invalid machine name') unless validate_name?
      load_cloud
      @cloud.create_machine(@name, @domain, @d.get_id,
                            @prvsubnetip, @mgtsubnetip, @type, @size, @d.get_region)
    end

    def destroy
      load_cloud
      @cloud.destroy(@name, @domain)
    end

    def list
      list = {}
      aws = Cloudware::Aws.new
      azure = Cloudware::Azure.new
      list.merge!(aws.machine_list)
      list.merge!(azure.machine_list)
      list
    end

    def get_list
      get_list ||= list
    end

    def get_prvsubnetip
      get_list[@name][:prv_ip]
    end

    def get_mgtsubnetip
      get_list[@name][:mgt_ip]
    end

    def get_extip
      get_list[@name][:extip]
    end

    def get_state
      get_list[@name][:state]
    end

    def get_size
      get_list[@name][:size]
    end

    def get_type
      get_list[@name][:cloudware_machine_type]
    end

    def get_provider
      get_list[@name][:provider]
    end

    def validate_name?
      !@name.match(/\A[a-zA-Z0-9]*\z/).nil?
    end
  end
end
