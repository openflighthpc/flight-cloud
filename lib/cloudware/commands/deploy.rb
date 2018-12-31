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
require 'cloudware/replacement_factory'

module Cloudware
  module Commands
    class Deploy < Command
      attr_reader :name, :template_path

      def run
        @name = argv[0]
        @template_path = File.expand_path(argv[1])
        begin
          with_spinner('Deploying resources...', done: 'Done') do
            deployment.deploy
          end
        ensure
          context.save_deployments(deployment)
        end
      end

      private

      def deployment
        Models::Deployment.new(
          template_path: template_path,
          name: name,
          context: context,
          region: region,
          replacements: ReplacementFactory.new(context, name)
                                          .build(options.params)
        )
      end
    end
  end
end
