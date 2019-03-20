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

module Cloudware
  module Models
    module DeploymentCallbacks
      def self.included(base)
        base.class_exec do
          validate :validate_template_exists
          validate :validate_replacement_tags
          validate :validate_cluster
        end
      end

      private

      def validate_template_exists
        return if File.exist?(template_path)
        if template_path.empty?
          errors.add(:template, 'Failed to resolve the template')
        else
          errors.add(:template, "No such template: #{template_path}")
        end
      end

      def validate_replacement_tags
        return unless File.exist?(template_path)
        template.scan(/%[\w-]*%/).each do |match|
          errors.add(match, 'Was not replaced in the template')
        end
      end

      def validate_cluster
        return if cluster
        errors.add(:cluster, 'No cluster specified')
      end
    end
  end
end
