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
require 'ipaddr'

module Cloudware
  class Machine < Domain
    attr_accessor :name
    attr_accessor :domain
    attr_accessor :prvip
    attr_accessor :mgtip
    attr_accessor :role
    attr_accessor :type
    attr_accessor :flavour

    def initialize
      @items = {}
    end

    def load_cloud
      @d = Cloudware::Domain.new
      @d.name = @domain
      case @d.get_item('provider')
      when 'azure'
        @cloud = Cloudware::Azure.new
      when 'aws'
        @cloud = Cloudware::Aws.new
      else
        @aws = Cloudware::Aws.new
        @azure = Cloudware::Azure.new
      end
    end

    def create
      raise('Invalid machine name') unless validate_name?
      raise("IP address #{prvip} is already in use") if ip_in_use? @prvip
      raise("IP address #{mgtip} is already in use") if ip_in_use? @mgtip
      load_cloud
      log.info("[#{self.class}] Creating new machine:\nName: #{name}\nDomain: #{domain}\nID: #{id}\nPrv IP: #{prvip}\nMgt IP: #{mgtip}\nType: #{type}\nFlavour: #{flavour}")
      @cloud.create_machine(@name, @domain, @d.get_item('id'),
                            @prvip, @mgtip, @role, render_type, @d.get_item('region'), @flavour)
    end

    def destroy
      load_cloud
      @cloud.destroy(@name, @domain)
    end

    def list
      @list ||= begin
                  @list = {}
                  aws = Cloudware::Aws.new
                  azure = Cloudware::Azure.new
                  log.debug("[#{self.class}] Loaded machines from AWS:\n#{aws.machines}")
                  @list.merge!(aws.machines)
                  log.debug("#{self.class}] Loaded machines from Azure:\n#{azure.machines}")
                  @list.merge!(azure.machines)
                  log.debug("#{self.class}] Detected machines:\n#{@list}")
                  @list
                end
    end

    def get_item(item)
      return @items[item] unless @items[item].nil?
      @items[item] = begin
                       list["#{@domain}-#{@name}"][item.to_sym]
                     end
    end

    def render_type
      mappings = YAML.load_file(Cloudware.render_file_path("#{@d.get_item('provider')}/mappings/machine_types.yml"))
      log.info("[#{self.class}] Rendering type provider: #{@d.get_item('provider')} flavour: #{@flavour} type: #{@type}")
      mappings[@flavour][@type]
    end

    def exists?
      return false if list["#{@domain}-#{@name}"].nil?
      return true if list["#{@domain}-#{@name}"][:domain].include? @domain
    end

    def validate_name?
      !@name.match(/\A[a-zA-Z0-9]*\z/).nil?
    end

    def valid_domain?
      domain = Cloudware::Domain.new
      domain.name = @domain
      true if domain.exists? || false
    end

    def valid_ip?(subnet, ip)
      subnet_ip = IPAddr.new(subnet)
      subnet_ip.include?(ip)
    end

    def ip_in_use?(ip)
      list.each do |k, v|
        if v[:domain] == @domain
          if v[:mgt_ip] == ip || v[:prv_ip] == ip
            log.warn("IP address #{ip} is in use by #{v[:name]}")
            return true
            break
          else
            return false
          end
        end
      end
    end
  end
end
