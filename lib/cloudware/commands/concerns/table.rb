# frozen_string_literal: true

module Cloudware
  module Commands
    module Concerns
      module Table
        def table
          @table ||= TTY::Table.new header: table_header
        end

        def render_table
          table.render(:unicode, multiline: true, width: table.width + 10)
        end
      end
    end
  end
end
