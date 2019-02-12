# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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

module Cloudware
  class RootDir
    def self.content(*a)
      File.join(Config.content_path, *a)
    end

    def self.content_cluster(cluster, *a)
      content('clusters', cluster, *a)
    end
  end
end
