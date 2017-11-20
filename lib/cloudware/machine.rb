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
require 'cloudware/domain'
require 'cloudware/azure'

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

    def create
      abort('Invalid machine name') unless validate_name
      p = Cloudware::Azure.new
      d = Cloudware::Domain.new
      domain_id = p.get_domain_id(@domain)
      d.name = @domain
      provider = d.domain_provider
      p.create_machine(@name,
                       @domain,
                       domain_id,
                       @prvsubnetip,
                       @mgtsubnetip,
                       @type,
                       @size)
    end

    def list
      # @todo - once we have GCP/AWS providers, merge
      # all providers data into a single hash and return
      azure = Cloudware::Azure.new
      azure.list_machines
    end

    def destroy; end

    def validate_name
      !@name.match(/\A[a-zA-Z0-9]*\z/).nil?
    end
  end
end
