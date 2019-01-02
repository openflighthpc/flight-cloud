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
    attr_reader :region, :deployments
    delegate :provider, to: Config

    def initialize(region: nil)
      @region = region || Config.default_region
      update_deployments
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
      update_deployments do
        delete_names = delete_deployments.map(&:name)
        deployments.delete_if { |d| delete_names.include?(d.name) }
      end
    end

    def save_deployments(*deployments)
      update_deployments do
        deployments.each { |deployment| add_deployment(deployment) }
      end
    end

    def find_deployment(name)
      deployments.find { |d| d.name == name }
    end

    def render(template)
      ERB.new(template, nil, '-').result(binding)
    end

    private

    def update_deployments
      with_file_lock do |file|
        @deployments = Data.load(file, default_value: []).map do |data|
          Models::Deployment.new(**data)
        end
        if block_given?
          yield
          save_data = deployments.map(&:to_h)
          file.truncate(0)
          Data.dump(file, save_data)
        end
      end
    end

    def add_deployment(deployment)
      existing_index = deployments.find_index do |cur_deployment|
        cur_deployment.name == deployment.name
      end
      if existing_index
        deployments[existing_index] = deployment
      else
        deployments.push(deployment)
      end
    end

    def with_file_lock
      file = File.new(path, 'r+')
      file.flock(File::LOCK_EX)
      yield file
    ensure
      file&.flock(File::LOCK_UN)
      file&.close
    end

    def path
      File.join(
        Config.content_path,
        'contexts',
        provider,
        "#{region}.yaml"
      ).tap { |p| FileUtils.mkdir_p(p) }
    end
  end
end
