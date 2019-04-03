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
  module Providers
    module Base
      module HasCredentials
        def credentials
          self.class.parent::Credentials.build
        end
      end

      class Credentials
        def self.build
          raise NotImplementedError
        end
      end

      class Machine
        extend Memoist
        include HasCredentials

        attr_reader :machine_id, :region

        def initialize(machine_id, region)
          @machine_id = machine_id
          @region = region
        end

        def status
          raise NotImplementedError
        end

        def off
          raise NotImplementedError
        end

        def on
          raise NotImplementedError
        end
      end

      class Client
        extend Memoist
        include HasCredentials

        attr_reader :region

        def initialize(region)
          @region = region
        end

        def deploy(_tag, _template)
          raise NotImplementedError
        end

        def destroy(_tag)
          raise NotImplementedError
        end

        def machine(id)
          self.class.parent::Machine.new(id, region)
        end
      end
    end
  end
end
