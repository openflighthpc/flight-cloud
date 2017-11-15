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
require 'google/cloud/resource_manager'

module Cloudware
  class Gcp
    attr_accessor :name, :networkcidr, :prvsubnetcidr, :mgtsubnetcidr, :region, :infrastructure

    def initialize
      @resource_manager = Google::Cloud::ResourceManager.new
    end

    def create_infrastructure
    end

    def list_infrastructure
    end

    def destroy_infrastructure
    end

    def create_domain
    end

    def list_domains
    end

    def destroy_domain
    end

    def create_machine
    end

    def list_machine
    end

    def destroy_machine
    end

    def deploy(template, type)
    end
  end
end
