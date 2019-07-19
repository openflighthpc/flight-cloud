# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

require 'cloudware/config'
require 'active_support/core_ext/module/delegation'

module Cloudware
  class CommandConfig
    include FlightConfig::Updater
    allow_missing_read

    delegate_missing_to Config

    def self.path(*_)
      File.join(Config.content_path, 'etc/config.yaml')
    end

    def current_cluster
      name = (server_mode ? server_cluster : __data__.fetch(:current_cluster))
      if name && File.exists?(Models::Cluster.path(name))
        name
      elsif name
        raise ConfigError, <<~ERROR.squish
          The current cluster '#{name}' does not exist. Please create it with
          '#{app_name} cluster init #{name} <provider>'
        ERROR
      else
        raise ConfigError, <<~ERROR.chomp
          Can not currently preform this operation as a cluster has not been selected.
          Please select a cluster using either:
          * '#{app_name} cluster init <new-cluster> <provider>
          * '#{app_name} cluster switch <existing-cluster>
        ERROR
      end
    end

    def current_cluster=(cluster)
      if server_mode
        raise ConfigError, <<~ERROR.chomp
          Can not change the current cluster when in server mode
        ERROR
      else
        __data__.set(:current_cluster, value: cluster)
      end
    end

    def region
      @region ||= Config.default_region
    end

    def region=(region)
      @region = region
    end
  end
end
