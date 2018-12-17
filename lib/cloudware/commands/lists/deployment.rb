# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Deployment < Command
        include Concerns::MarkdownTemplate

        TEMPLATE = <<-TEMPLATE
<% deployments.each do |deployment| -%>
# Deployment: '<%= deployment.name %>'
*Template*: <%= deployment.template_path %>

## Results
<% deployment.results.each do |key, value| -%>
- *<%= key %>*: <%= value %>
<% end -%>

## Replacements
<% deployment.replacements.each do |key, value| -%>
- *<%= key %>*: <%= value %>
<% end -%>

<% end -%>
TEMPLATE
      end
    end
  end
end
