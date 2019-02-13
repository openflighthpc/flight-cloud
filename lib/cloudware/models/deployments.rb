# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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

require 'cloudware/models/deployment'

module Cloudware
  module Models
    class Deployments < DelegateClass(Array)
      REGEX = /#{Deployment.new('(?<cluster>.*)', '(?<name>.*)').path}/

      def self.read(cluster)
        d = Dir.glob(Deployment.new(cluster, '*').path)
               .map { |p| read_match(REGEX.match(p)) }
        new(d)
      end

      private_class_method

      def self.read_match(match)
        Deployment.read(match['cluster'], match['name'])
      end

      def results
        map(&:results).each_with_object({}) do |results, memo|
          memo.merge!(results || {})
        end
      end

      def find_by_name(name)
        find { |deployment| deployment.name == name }
      end

      def machines
        results.keys
               .map { |k| Models::Machine.name_from_tag(k) }
               .uniq
               .reject(&:nil?)
               .map { |n| Models::Machine.new(name: n, cluster: first.cluster) }
      end
    end
  end
end
