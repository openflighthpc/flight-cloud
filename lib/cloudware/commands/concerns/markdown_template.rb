# frozen_string_literal: true

require 'pager'
require 'tty-color'
require 'tty-markdown'

module Cloudware
  module Commands
    module Concerns
      module MarkdownTemplate
        include Pager

        def run
          pager_puts(TTY::Markdown.parse(rendered_markdown))
        end

        def rendered_markdown
          context.render(self.class::TEMPLATE)
        end
      end
    end
  end
end
