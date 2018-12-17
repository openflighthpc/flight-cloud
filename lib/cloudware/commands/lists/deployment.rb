# frozen_string_literal: true

require 'pager'
require 'tty-color'
require 'tty-markdown'

module Cloudware
  module Commands
    module Lists
      class Deployment < Command
        include Pager

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

        def run
          pager_puts(TTY::Markdown.parse(rendered_markdown))
        end

        def rendered_markdown
          context.render(TEMPLATE)
        end
      end
    end
  end
end
