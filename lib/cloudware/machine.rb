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
  class Machine
    attr_accessor :name
    attr_accessor :domain
    attr_accessor :prvsubnetaddress
    attr_accessor :mgtsubnetaddress
    # type: Cloudware instance type, e.g. master,slave
    attr_accessor :type
    # size: Provider specific VM size
    attr_accessor :size

    def create
      case @provider
      when 'azure'
        p = Cloudware::Azure.new
      end
      p.name = @name
      p.domain = @domain
      p.prvsubnetaddress = @prvsubnetaddress
      p.mgtsubnetaddress = @mgtsubnetaddress
      p.type = @type
      p.size = @size
      p.create_machine
    end

    def list; end

    def destroy; end
  end
end
