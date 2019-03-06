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
  module Commands
    class Destroy < Command
      attr_reader :name

      def initialize(*a)
        require 'cloudware/models/deployment'
        super
      end

      def run
        @name = argv[0]
        with_spinner('Destroying resources...', done: 'Done') do
          Models::Deployment.destroy!(__config__.current_cluster, name)
        end
      end

      def delete(name, force: false)
        if force
          Models::Deployment.delete(__config__.current_cluster, name)
        else
          Models::Deployment.delete!(__config__.current_cluster, name)
        end
      end
    end
  end
end
