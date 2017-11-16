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

module Cloudware
  class Infrastructure
    require 'cloudware/azure'
    require 'cloudware/gcp'

    attr_accessor :name, :provider, :region

    def create
      case @provider
      when 'azure'
        p = Cloudware::Azure.new
        p.region = @region
      when 'gcp'
        p = Cloudware::Gcp.new
      end
      p.name = @name
      p.create_infrastructure
    end

    def list
      l = []
      case @provider
      when 'azure'
        p = Cloudware::Azure.new
        l.push(p.list_infrastructure)
      when 'gcp'
        p = Cloudware::Gcp.new
      else
        azure = Cloudware::Azure.new
        l.push(azure.list_infrastructure)
      end
      l
    end

    def destroy
      case @provider
      when 'azure'
        p = Cloudware::Azure.new
      end
      p.name = @name
      p.destroy_infrastructure
    end

    def check_infrastructure_exists
      list.each do |i|
      	i.each do |l|
          next unless l[0] == @name
          return true if l[0] == @name
      	end
      end
    end
  end
end
