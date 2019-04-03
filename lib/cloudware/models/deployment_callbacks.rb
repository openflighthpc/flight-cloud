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
