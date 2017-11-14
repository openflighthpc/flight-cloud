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
  class Azure
    require 'azure_mgmt_resources'

    attr_accessor :name, :networkcidr, :subnets, :region, :infrastructure

    def initialize
    end

    def create_infrastructure
      puts "#{@name}"
    end

    def list_infrastructure
    end

    def destroy_infrastructure
    end

    def create_domain
    end

    def list_domain
    end

    def destroy_domain
    end

    def create_machine
    end

    def list_machine
    end

    def destroy_machine
    end
  end
end
