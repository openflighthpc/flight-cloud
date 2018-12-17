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
# Deployment: <%= deployment.name %>
template: <%= deployment.template_path %>

## Results
<% deployment.results.each do |key, value| -%>
- <%= key %>: <%= value %>
<% end -%>

## Replacements
<% Replacements -%>
<% deployment.replacements.each do |key, value| %>
- <%= key %>: <%= value %>
<% end -%>

<% end -%>
TEMPLATE

        def run
          pager_puts(TTY::Markdown.parse(TEMPLATE))
        end
      end
    end
  end
end
