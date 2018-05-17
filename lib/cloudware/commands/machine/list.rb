# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class List < Command
        def run
          m = Cloudware::Machine.new
          m.provider = [options.provider]

          r = []
          m.list.each do |_k, v|
            r << [v[:name], v[:domain], v[:role], v[:pri_ip], v[:type], v[:state]]
          end
          table = Terminal::Table.new headings: ['Name'.bold,
                                                 'Domain'.bold,
                                                 'Role'.bold,
                                                 'Pri IP address'.bold,
                                                 'Type'.bold,
                                                 'State'.bold],
                                      rows: r
          puts table
        end
      end
    end
  end
end
