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

require 'cloudware/config'

#
# NOTE: To future maintainer!
#
# Please keep this file as lean as possible. It is design to contain the root
# path definition between different types of files. It should not contain the
# path definition for an individual file.
#
# When adding a new path, make sure name maps to the arguments!
#
# NOTE: Optional: [last_named_argument]
# The last named argument to these methods should be optional, so calling it
# without arguments gives the directory. e.g.
#
# content_cluster()             => .../clusters
# content_cluster('my-cluster)  => .../clusters/my-cluster
#
# It is however required for all dependent method calls. e.g:
# content_cluster_template(cluster, [template])
#

module Cloudware
  class RootDir
    def self.content(*parts)
      File.join(Config.content_path, *parts)
    end

    def self.content_cluster(*a) # [cluster]
      content('clusters', *a)
    end

    def self.content_cluster_template(cluster, *a) # [template]
      content_cluster(cluster, 'lib/templates', *a)
    end
  end
end
