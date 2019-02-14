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
    module Lists
      class Deployment < Command
        TEMPLATE = <<~ERB
          # Deployment: '<%= deployment.name %>'
          <% if deployment.deployment_error -%>
          *ERROR*: An error occured whilst deploying this template
          <% unless verbose -%>
          Please use `--verbose` for further details
          <% end -%>

          <% end -%>
          *Creation Date*: <%= deployment.timestamp %>
          *Template*: <%= deployment.template_path %>
          *Provider Tag*: <%= deployment.tag %>

          ## Results
          <% if deployment.results.nil? || deployment.results.empty? -%>
          No deployment results
          <% else -%>
          <% deployment.results.each do |key, value| -%>
          - *<%= key %>*: <%= value %>
          <% end -%>
          <% end -%>

          <% if deployment.replacements -%>
          ## Replacements
          <% deployment.replacements.each do |key, value| -%>
          - *<%= key %>*: <%= value %>
          <% end -%>

          <% end -%>
          <% if verbose && deployment.deployment_error -%>
          ## Error
          *NOTE:* This is `<%= provider %>'s` raw error message
          Refer to their documentation for further details

          ```
          <%= deployment.deployment_error %>
          ```

          <% end -%>
        ERB

        def self.delayed_require
          require 'tty-markdown'
          require 'cloudware/models/deployments'
        end

        def run!(verbose: false)
          deployments = Models::Deployments.read(__config__.current_cluster)
          return puts 'No Deployments found' if deployments.empty?
          deployments.each do |deployment|
            puts TTY::Markdown.parse(ERB.new(TEMPLATE, nil, '-').result(binding))
          end
        end
      end
    end
  end
end
