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

require 'cloudware/templater'

module Cloudware
  module Templaters
    class DeploymentTemplater < Templater
      attr_reader :verbose

      def initialize(obj, verbose: false)
        super(obj)
        @verbose = verbose
      end

      def render_info
        render_markdown <<~ERB
          # Deployment: '<%= name %>'
          <% if deployment_error -%>
          *ERROR*: An error occured whilst deploying this template
          <% unless verbose -%>
          Please use `--verbose` for further details
          <% end -%>

          <% end -%>
          *Creation Date*: <%= timestamp %>
          *Status*: <%= deployed ? 'Running' : 'Offline' %>
          *Template*: <%= template_path %>
          *Provider Tag*: <%= tag %>

          ## Results
          <% if results.nil? || results.empty? -%>
          No deployment results
          <% else -%>
          <% results.each do |key, value| -%>
          - *<%= key %>*: <%= value %>
          <% end -%>
          <% end -%>

          <% if replacements -%>
          ## Replacements
          <% replacements.each do |key, value| -%>
          - *<%= key %>*: <%= value %>
          <% end -%>

          <% end -%>
          <% if verbose && deployment_error -%>
          ## Error
          *NOTE:* This is `<%= provider %>'s` raw error message
          Refer to their documentation for further details

          ```
          <%= deployment_error %>
          ```

          <% end -%>
        ERB
      end
    end
  end
end
