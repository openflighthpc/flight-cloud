# frozen_string_literal: true

require 'pager'

module Cloudware
  module Commands
    module Concerns
      module Table
        include Pager

        def table
          @table ||= TTY::Table.new header: table_header
        end

        def page_table
          pager_puts(render_table)
        end

        def render_table
          table.render(:unicode) do |renderer|
            renderer.multiline = true
            renderer.width = table.width + 10
            renderer.border.separator = :each_row
          end
        end
      end
    end
  end
end
