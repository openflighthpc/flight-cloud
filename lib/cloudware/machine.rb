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
      case @d.provider
      when 'azure'
        @cloud = Cloudware::Azure.new
      when 'aws'
        @cloud = Cloudware::Aws.new
      end
    end

    def create
      abort('Invalid machine name') unless validate_name
      load_cloud
      @cloud.create_machine(@name, @domain, @d.id,
                            @prvsubnetip, @mgtsubnetip, @type, @size, @d.region)
    end

    def list
      # @todo - once we have GCP/AWS providers, merge
      # all providers data into a single hash and return
      list = {}
      azure = Cloudware::Azure.new
      aws = Cloudware::Aws.new
      list.merge!(azure.list_machines)
      list.merge!(aws.machines)
      list
    end

    def prvsubnetip
      list[@name][:prv_ip] || @prvsubnetip
    end

    def mgtsubnetip
      list[@name][:mgt_ip] || @mgtsubnetip
    end

    def extip
      list[@name][:extip] || @extip
    end

    def state
      list[@name][:state] || @state
    end

    def size
      list[@name][:size] || @size
    end

    def type
      list[@name][:cloudware_machine_type] || @type
    end

    def provider
      list[@name][:provider] || @provider
    end

    def destroy
      load_cloud
      @cloud.destroy(@name, @domain)
    end

    def validate_name
      !@name.match(/\A[a-zA-Z0-9]*\z/).nil?
    end
  end
end
