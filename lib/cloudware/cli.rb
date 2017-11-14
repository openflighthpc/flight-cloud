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
require 'commander'
require 'terminal-table'

module Cloudware

  class CLI
    extend Commander::UI
    extend Commander::UI::AskForClass
    extend Commander::Delegates

    program :name, 'cloudware'
    program :version, '0.0.1'
    program :description, 'Cloud orchestration tool'

    command :'domain create' do |c|
      c.syntax = 'cloudware domain create [options]'
      c.description = 'Create a new domain'
      c.option '--name NAME', String, 'Domain identifier/name'
      c.option '--networkcidr CIDR', String, 'Network CIDR'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--subnets LIST', String, 'Comma delimited subnet list e.g. prv:192.168.1.0/24,mgt:192.168.2.0/24'
      c.option '--region NAME', String, 'Region name to deploy into'
      c.action { |args, options|
      }
    end

    command :'domain list' do |c|
      c.syntax = 'cloudware domain list [options]'
      c.description = 'List domains'
      c.option '--provider NAME', String, 'Provider name'
      c.action { |args, options|
        options.default \
            :provider => 'azure'
        Cloudware::Domain.list("#{options.provider}")
      }
    end

    command :'domain destroy' do |c|
      c.syntax = 'cloudware domain destroy [options]'
      c.description = 'Destroy a domain and all the resources contained in a domain'
      c.option '--name NAME', String, 'Domain name'
      c.option '--provider NAME', String, 'Provider name'
      c.action { |args, options|
        agree("==> Are you sure you wish to destroy this domain? [yes/no]")
        Cloudware::Domain.destroy("#{options.name}", "#{options.provider}")
      }
    end
  end

end
