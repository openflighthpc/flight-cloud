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
    attr_accessor :name, :networkcidr, :prvsubnetcidr, :mgtsubnetcidr, :provider, :region
    attr_accessor :name
    attr_accessor :id
    attr_accessor :networkcidr
    attr_accessor :prvsubnetcidr
    attr_accessor :mgtsubnetcidr
    attr_accessor :region
    attr_accessor :provider

    def create
      case @provider
      when 'azure'
        d = Cloudware::Azure.new
      end
      @id = SecureRandom.uuid
      d.create_domain(@name,
                      @id,
                      @networkcidr,
                      @prvsubnetcidr,
                      @mgtsubnetcidr,
                      @region)
    end

    def list
      azure = Cloudware::Azure.new
      return azure.list_domains
    end

    def get_domain_provider
      list.each do |d|
        d.each do |l|
          next unless l[0] == @name
          l[4]
        end
      end
    end
  end
end
