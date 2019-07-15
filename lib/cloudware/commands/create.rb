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
  module Commands
    class Create < Command
      def run!(name, template)
        abs_template = File.expand_path(template)
        name == 'domain' ? domain(abs_template) : node(name, abs_template)
      end

      def domain(abs_template)
        Models::Domain.create!(__config__.current_cluster) do |domain|
          domain.save_template(abs_template)
          domain.prompt_for_missing_replacements
        end
      end

      def node(name, abs_template)
        Models::Node.create!(__config__.current_cluster, name) do |node|
          node.save_template(abs_template)
          node.prompt_for_missing_replacements
        end
      end
    end
  end
end
