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
      c.option '--infrastructure NAME', String, 'Infrastructure identifier'
      c.option '--networkcidr CIDR', String, 'Primary network CIDR, e.g. 10.0.0.0/16'
      c.option '--subnets LIST', String, 'Comma delimited subnet list, e.g. prv:10.0.1.0/24,mgt:10.0.2.0/24'
      c.option '--provider NAME', String, 'Provider name'
      c.action { |args, options|
        i = Cloudware::Infrastructure.new
        i.name="#{options.infrastructure}"
        i.provider="#{options.provider}"
        if i.list.include?("#{options.infrastructure}")
          d = Cloudware::Domain.new
          d.name="#{options.infrastructure}"
          d.infrastructure="#{options.infrastructure}"
          d.networkcidr="#{options.networkcidr}"
          d.provider="#{options.provider}"
          d.create
        else
          abort("==> Infrastructure group #{options.infrastructure} does not exist")
        end
      }
    end

    command :'infrastructure create' do |c|
      c.syntax = 'cloudware infrastructure create [options]'
      c.description = 'Interact with infrastructure groups'
      c.option '--name NAME', String, 'Infrastructure identifier'
      c.option '--provider NAME', String, 'Provider name'
      c.option '--region NAME', String, 'Region name to deploy into'
      c.action { |args, options|
        i = Cloudware::Infrastructure.new
        i.name="#{options.name}"
        i.provider="#{options.provider}"
        i.region="#{options.region}"
        i.create
      }
    end

    command :'infrastructure list' do |c|
      c.syntax = 'cloudware infrastructure list [options]'
      c.description = 'List infrastructure groups'
      c.option '--provider NAME', String, 'Provider name'
      c.action { |args, options|
        i = Cloudware::Infrastructure.new
        i.provider = "#{options.provider}"
        puts i.list
      }
    end

    command :'infrastructure destroy' do |c|
      c.syntax = 'cloudware infrastructure destroy [options]'
      c.description = 'Destroy infrastructure groups'
      c.option '--name NAME', String, 'Infrastructure identifier'
      c.option '--provider NAME', String, 'Provider name'
      c.action { |args, options|
        i = Cloudware::Infrastructure.new
        i.name = "#{options.name}"
        i.provider = "#{options.provider}"
        i.destroy
      }
    end
  end

end
