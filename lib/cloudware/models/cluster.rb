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

require 'cloudware/root_dir'
require 'securerandom'

module Cloudware
  module Models
    class Cluster
      include FlightConfig::Updater
      include FlightConfig::Globber

      def self.create!(cluster)
        create(cluster) do |config|
          # Ensure the tag has been assigned
          config.tag
        end
      end

      delegate :provider, to: Config

      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def __data__initialize(data)
        data.set(:tag, value: SecureRandom.hex(5))
      end

      def path
        RootDir.content_cluster(identifier, 'etc/config.yaml')
      end

      def templates
        @templates ||= ListTemplates.new(identifier)
      end

      def region
        __data__.fetch(:region) { Config.default_region }
      end

      def tag
        __data__.fetch(:tag)
      end

      def deployments
        Models::Deployments.read(identifier)
      end
    end
  end
end
