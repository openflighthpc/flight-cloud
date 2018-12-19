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

require 'models/application'
require 'models/concerns/provider_client'

module Cloudware
  module Models
    class Machine < Application
      include Concerns::ProviderClient
      include Concerns::ModelTags

      PROVIDER_ID_FLAG = 'ID'
      GROUPS_TAG = 'groups'

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :context

      def provider_id
        fetch_result(PROVIDER_ID_FLAG) do |long_tag|
          raise ModelValidationError, <<-ERROR.squish
            Machine '#{name}' is missing its provider ID. Make sure
            '#{long_tag}' is set within the deployment output
          ERROR
        end
      end

      def groups
        fetch_result(GROUPS_TAG, default: '').split(',')
      end

      private

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
