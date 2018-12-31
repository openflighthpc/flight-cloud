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

require 'cloudware/models/deployment'

module Cloudware
  module Commands
    class Destroy < Command
      attr_reader :name

      def run
        @name = argv[0]
        with_spinner('Destroying resources...', done: 'Done') do
          deployment.context = context # TODO: Remove this by refactoring context
          deployment.destroy
        end
      ensure
        context.remove_deployments(deployment)
      end

      private

      def deployment
        context.find_deployment(name).tap do |deployment|
          if deployment.nil?
            raise InvalidInput, <<~ERROR.chomp
              Could not find deployment '#{name}'
            ERROR
          end
        end
      end
    end
  end
end
