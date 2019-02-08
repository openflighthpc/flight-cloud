# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
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
  class Context
    attr_reader :deployments, :cluster

    # TODO: Try and remove the provider as `Config.content_path` is now provider
    # specific
    delegate :provider, to: Config

    def initialize(cluster:)
      @cluster = cluster
    end

    def deployments
      Models::Deployments.read(cluster)
    end

    def machines
      Models::Machine.build_from_context(self)
    end

    def results
      deployments.map(&:results)
                 .each_with_object({}) do |results, memo|
        memo.merge!(results || {})
      end
    end

    def remove_deployments(*delete_deployments)
      deployments.each do |deployment|
        FileUtils.rm_f deployment.path
      end
    end

    def save_deployments(*deployments)
      deployments.each do |deployment|
        FlightConfig::Core.write(deployment)
      end
    end

    def find_deployment(name)
      deployments.find { |d| d.name == name }
    end

    def render(template, verbose: false)
      ERB.new(template, nil, '-').result(binding)
    end

    def reload
    end

    def region
      # Protect `Cluster` from the `nil` cluster. This weird state would
      # be picked up by `Deployment` validation
      Cluster.load(cluster.to_s).region
    end
  end
end
