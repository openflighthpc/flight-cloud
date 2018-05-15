# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class List < Command
        def run
          rows = Providers.select(options.provider)::Domains
                          .by_region(options.region)
                          .reduce([]) do |memo, domain|
                            memo << [
                              domain.name,
                              domain.networkcidr,
                              domain.prisubnetcidr,
                              domain.provider,
                              domain.region
                            ]
                          end
          table = Terminal::Table.new headings: ['Domain name'.bold,
                                                 'Network CIDR'.bold,
                                                 'Pri Subnet CIDR'.bold,
                                                 'Provider'.bold,
                                                 'Region'.bold],
                                      rows: rows
          puts table
        end

        def required_options
          [:provider, :region]
        end
      end
    end
  end
end
