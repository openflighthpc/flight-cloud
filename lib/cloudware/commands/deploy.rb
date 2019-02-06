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

require 'cloudware/cluster'

module Cloudware
  module Commands
    class Deploy < Command
      def initialize(*a)
        require 'cloudware/models/deployment'
        require 'cloudware/replacement_factory'
        super
      end

      def run
        @name = argv[0]
        @raw_path = Pathname.new(argv[1])
        with_spinner('Deploying resources...', done: 'Done') do
          deployment.deploy
        end
      end

      private

      attr_reader :name, :raw_path

      def template_path
        return raw_path if raw_path.absolute?
        cluster = Cluster.load(__config__.current_cluster)
        path = cluster.template(raw_path)
        nested_path = cluster.template(raw_path, path.basename, ext: false)
        return nested_path if !path.file? && nested_path.file?
        path
      end

      def deployment
        puts "Deploying: #{template_path}"
        Models::Deployment.new(
          template_path: template_path,
          name: name,
          cluster: __config__.current_cluster,
          replacements: ReplacementFactory.new(context, name)
                                          .build(options.params)
        )
      end
    end
  end
end
