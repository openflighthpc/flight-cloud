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

require 'tty-editor'

module Cloudware
  module Commands
    class Edit < ScopedCommand
      def domain(*a)
        # NOTE: Currently their is a distinction between Models::Domain and
        # Models::Cluster. This will eventually be removed, but in the meantime
        # it should not be exposed to the user. As such the domain can be implicitly
        # created
        unless File.exists?(Models::Domain.path(name_or_error))
          model = Models::Domain.create(name_or_error)
          FileUtils.mkdir_p File.dirname(model.template_path)
          FileUtils.touch model.template_path
        end
        run(*a)
      end

      def run(template = nil)
        model_klass.update(*read_model.__inputs__) do |node|
          if template
            node.save_template(template)
          else
            node.edit_template
          end
        end
      end
    end
  end
end
