# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class List < Command
        def run
          rows = search_regions.reduce([]) do |memo, region|
            add_domain_rows_in_region(memo, options.provider, region)
          end
          table = Terminal::Table.new headings: headers, rows: rows
          puts table
        end

        private

        def search_regions
          if options.all_regions
            Providers.select(options.provider).regions
          else
            Array.wrap(options.region)
          end
        end

        def headers
          [
            'Domain name'.bold,
            'Network CIDR'.bold,
            'Pri Subnet CIDR'.bold,
          ].tap do |x|
            if options.all_regions
              x << 'Provider'.bold
              x << 'Region'.bold
            end
          end
        end

        def add_domain_rows_in_region(current_rows, provider, region)
          Providers.select(provider)::Domains
            .by_region(region)
            .reduce(current_rows) do |memo, domain|
            memo << [
              domain.name,
              domain.networkcidr,
              domain.prisubnetcidr,
            ].tap do |x|
              if options.all_regions
                x << domain.provider
                x << domain.region
              end
            end
          end
        end
      end
    end
  end
end
