# frozen_string_literal: true

require 'tty-color'
require 'tty-markdown'

module Cloudware
  module Commands
    module Concerns
      module MarkdownTemplate
        def run
          puts TTY::Markdown.parse(rendered_markdown)
        end

        def rendered_markdown
          context.render(self.class::TEMPLATE)
        end
      end
    end
  end
end
