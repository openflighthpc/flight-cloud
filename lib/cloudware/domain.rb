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
require 'ipaddr'

module Cloudware
    class Domain
        attr_accessor :name, :id, :region, :provider
        attr_accessor :networkcidr, :prvcidr, :mgtcidr
        attr_reader :mgtsubnetid, :prvsubnetid, :networkid

        include Utils

        def create
            client.create_domain(options)
        end

        def destroy
            client.destroy_domain(options)
        end

        def list
            @list ||= begin
                @list = {}
                @list.merge!(client.send(list_command)) if @provider
                if not @provider
                    providers.each do |p|
                        @list.merge!(client(p).send(list_command))
                    end
                end
                @list
            end
        end

        private

        def aws
            @aws ||= Cloudware::Aws.new(options)
        end

        def azure
            @azure ||= Cloudware::Azure.new
        end

        def client(provider = @provider)
            self.send(provider)
        end

        def list_command
            self.class == 'Cloudware::Domain' ? 'machines' : 'domains'
        end

        def options
            {
                domain: @name,
                region: @region,
                networkcidr: @networkcidr,
                mgtcidr: @mgtcidr,
                prvcidr: @prvcidr,
                provider: @provider
            }
        end

        def provider
            self.instance_variable_set(provider, list[@name][:provider]) unless @provider
        end
    end
end
