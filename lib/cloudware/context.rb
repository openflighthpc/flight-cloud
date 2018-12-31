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
    attr_reader :region
    delegate :provider, to: Config

    def initialize(region: nil)
      @region = region || Config.default_region
    end

    def deployments
      @deployments ||= Data.load(path, default_value: []).map do |data|
        Models::Deployment.new(**data)
      end
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

    # NOTE: Deprecated, to be removed
    def with_deployment(deployment)
      existing_index = deployments.find_index do |cur_deployment|
        cur_deployment.name == deployment.name
      end
      if existing_index
        deployments[existing_index] = deployment
      else
        deployments.push(deployment)
      end
    end

    def remove_deployment(deployment)
      deployments.delete_if { |d| d.name == deployment.name }
    end

    def save_deployments(*deployments)
      deployments.each { |deployment| with_deployment(deployment) }
      save
    end

    def save
      save_data = deployments.map(&:to_h)
      Data.dump(path, save_data)
    end

    def find_deployment(name)
      deployments.find { |d| d.name == name }
    end

    def render(template)
      ERB.new(template, nil, '-').result(binding)
    end

    private

    def path
      File.join(Config.content_path,
                'contexts',
                provider,
                "#{region}.yaml")
    end
  end
end
