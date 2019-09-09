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

require 'tty-color'

module Cloudware
  module Commands
    module Concerns
      module MarkdownTemplate
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def delayed_require
            super
            require 'cloudware/models/deployments'
            require 'tty-markdown'
          end
        end

        RenderCluster = Struct.new(:cluster_identifier) do
          delegate_missing_to :cluster

          def cluster
            @cluster ||= Profile.read(cluster_identifier)
          end

          def deployments
            @deployments ||= Models::Deployments.read(cluster_identifier)
          end

          def render(template, verbose: false)
            ERB.new(template, nil, '-').result(binding)
          end
        end

        def run
          puts TTY::Markdown.parse(rendered_markdown)
        end

        def rendered_markdown
          RenderCluster.new(__config__.current_cluster)
                       .render(self.class::TEMPLATE, verbose: options.verbose)
        end
      end
    end
  end
end
