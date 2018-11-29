# frozen_string_literal: true

module Cloudware
  module Commands
    module Concerns
      module Table
        def table
          @table ||= TTY::Table.new header: table_header
        end
      end
    end
  end
end
