# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Deployment < Command

        TEMPLATE = <<-TEMPLATE
<% deployments.each do |deployment| -%>
# Deployment: <%= deployment.name %>
template: <%= deployment.template_path %>

## Results
<% deployment.results.each do |key, value| -%>
<%= key %>: <%= value %>
<% end -%>

## Replacements
<% Replacements -%>
<% deployment.replacements.each do |key, value| %>
<%= key %>: <%= value %>
<% end -%>

<% end -%>
TEMPLATE

        def run
        end
      end
    end
  end
end
