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

require 'cloudware/models/deployment'

module Cloudware
  module Models
    class Domain < Deployment
      allow_missing_read

      def self.join_domain_path(cluster, *rest)
        RootDir.content_cluster(cluster.to_s, 'var/domain', *rest)
      end

      # TODO: make this match the initialize
      def self.path(cluster, *_a)
        join_domain_path(cluster, 'etc', 'config.yaml')
      end

      # TODO: Replace the Deployment initialize with
      # raise NotImplementedError
      def initialize(cluster, **h)
        super(cluster, nil, **h)
      end

      def name
        'domain'
      end

      def template_path
        ext = links.cluster.template_ext
        self.class.join_domain_path(cluster, 'var', 'template' + ext)
      end

      # TODO: Remove this once the base class stops setting the template path
      def template_path=(*a)
        # noop
      end
    end
  end
end

