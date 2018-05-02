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
      @provider = Cloudware.config.instance_variable_get(:@providers)
    end

    def load_cloud
      @d = Cloudware::Domain.new
      @d.name = @domain
      case @d.get_item('provider')
      when 'azure'
        @cloud = Cloudware::Azure.new
      when 'aws'
        @cloud = Cloudware::Aws2.new
      else
        @aws = Cloudware::Aws2.new
        @azure = Cloudware::Azure.new
      end
    end

    def info
      {
        name: @name,
        domain: @domain,
        id: get_item('id'),
        prvip: get_item('prv_ip'),
        mgtip: get_item('mgt_ip'),
        role: get_item('role'),
        type: get_item('type'),
        region: get_item('region'),
        state: get_item('state')
      }
    end

    def create
      raise('Invalid machine name') unless validate_name?
      # raise("IP address #{prvip} is already in use") if ip_in_use? @prvip
      # raise("IP address #{mgtip} is already in use") if ip_in_use? @mgtip
      load_cloud
      log.info("[#{self.class}] Creating new machine:\nName: #{name}\nDomain: #{domain}\nID: #{id}\nPrv IP: #{prvip}\nMgt IP: #{mgtip}\nType: #{type}\nFlavour: #{flavour}")
      @cloud.create_machine(@name, @domain, @d.get_item('id'),
                            @prvip, @mgtip, @role, render_type, @d.get_item('region'), @flavour)
    end

    def destroy
      load_cloud
      @cloud.destroy(@name, @domain)
    end

    def rebuild
      load_cloud
      machine_info = info
      destroy
      @cloud.create_machine(machine_info[:name],
                            machine_info[:domain],
                            machine_info[:id],
                            machine_info[:prvip],
                            machine_info[:mgtip],
                            machine_info[:role],
                            machine_info[:type],
                            @d.get_item('region'),
                            machine_info[:type])
    end

    def _load_machines(provider)
      case provider
      when 'aws'
        cloud = Cloudware::Aws2.new
      when 'azure'
        cloud = Cloudware::Azure.new
      else
        raise "Provider #{provider} doesn't exist"
      end
      log.debug("[#{self.class}] Loaded machines from #{provider}:\n#{cloud.machines}")
      return cloud.machines
    end

    def list
      @list ||= begin
                  @list = {}
=begin
                  case @provider
                  when 'aws'
                    @list.merge!(self._load_machines('aws'))
                  when 'azure'
                    @list.merge!(self._load_machines('azure'))
                  else
                    @list.merge!(self._load_machines('aws'))
                    @list.merge!(self._load_machines('azure'))
                  end
=end
                  @provider.each do |a|
                    @list.merge!(self._load_machines(a))
                  end
                  log.debug("[#{self.class}] Detected machines:\n#{@list}")
                  @list
                end
    end

    def get_item(item)
      return @items[item] unless @items[item].nil?
      @items[item] = begin
                       list["#{@domain}-#{@name}"][item.to_sym]
                     end
    end

    def power_status
      info.state
    end

    def power_on
      load_cloud
      @cloud.machine_power_on(@name, @domain)
    end

    def power_off
      load_cloud
      @cloud.machine_power_off(@name, @domain)
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
      list.each do |_k, v|
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
