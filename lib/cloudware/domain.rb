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
    class Domain
        attr_accessor :domain, :id, :region, :provider
        attr_writer :networkcidr, :prvcidr, :mgtcidr

        include Utils

        def list
            @list ||= begin
              @list = {}
              @list.merge!(client.send(list_command)) if @provider
              if not @provider
                  providers.each do |p|
                    result = client(p).send(list_command)
                    @list.merge!(result)
                  end
              end
              @list
            end
        end

        private

        def aws
            @aws ||= Cloudware::Aws.new(options)
        end

        def client(provider = @provider)
            self.send(provider)
        end

        def list_command
            self.class == 'Cloudware::Domain' ? 'machines' : 'domains'
        end

        def options
            instance_variables.map do |var|
                [var[1..-1].to_sym, instance_variable_get(var)]
            end.to_h
        end
    end
end
