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

require 'cloudware/config'
require 'active_support/core_ext/module/delegation'

module Cloudware
  class CommandConfig
    include FlightConfig::Updater

    delegate_missing_to Config

    def path
      File.join(content_path, 'etc/config.yaml')
    end

    def current_cluster
      __data__.fetch(:current_cluster) { 'default' }
    end

    def current_cluster=(cluster)
      __data__.set(:current_cluster, value: cluster)
    end
  end
end

