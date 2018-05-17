# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class List < Command
        def run
          rows = Providers.select(options.provider)::Machines
                          .by_region(options.region)
                          .reduce([]) do |memo, machine|
                            memo << [
                              machine.name,
                              machine.domain.name,
                              machine.role,
                              machine.priip,
                              machine.type,
                              machine.state
                            ]
                          end
          table = Terminal::Table.new headings: ['Name'.bold,
                                                 'Domain'.bold,
                                                 'Role'.bold,
                                                 'Pri IP address'.bold,
                                                 'Type'.bold,
                                                 'State'.bold],
                                      rows: rows
          puts table
        end
      end
    end
  end
end
