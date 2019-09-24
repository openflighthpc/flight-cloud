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
    class Edit < Command
      def run!(name, **kwargs)
        name == 'domain' ? domain(**kwargs) : node(name, **kwargs)
      end

      def domain(template: nil, **_kwargs)
      # NOTE: The domain can be implicitly created as their can only be one domain
        unless File.exists?(Models::Domain.path(__config__.current_cluster))
          model = Models::Domain.create(__config__.current_cluster)
          FileUtils.mkdir_p File.dirname(model.template_path)
          FileUtils.touch model.template_path
        end
        if template
          replace_model_template(
            template, Models::Domain.read(__config__.current_cluster)
          )
          Models::Domain.prompt!({}, __config__.current_cluster, all: true)
        else
          Models::Domain.edit_then_prompt!(__config__.current_cluster)
        end
      end

      def node(name, template: nil, groups: nil)
        Models::Node.update(__config__.current_cluster, name) do |node|
          if template
            node.save_template(template)
          else
            node.edit_template
          end
          node.prompt_for_missing_replacements
          node.cli_groups = groups
        end
      end

      private

      def replace_model_template(template, model)
        FileUtils.mkdir_p File.dirname(model.template_path)
        FileUtils.cp template, model.template_path
      end
    end
  end
end
