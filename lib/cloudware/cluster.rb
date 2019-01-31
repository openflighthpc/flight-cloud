# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Flight Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

module Cloudware
  class Cluster
    include FlightConfig::Loader

    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def directory
      Config.content('clusters', identifier)
    end

    def path
      File.join(directory, 'etc/config.yaml')
    end

    def template(*parts, ext: true)
      path = File.join(directory, 'templates', *parts)
      ext ? "#{path}#{Config.template_ext}" : path
    end

    def region
      Config.default_region
    end
  end
end
