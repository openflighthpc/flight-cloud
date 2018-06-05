# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class List < Command
        def run
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

        def domains
          domains_class = Providers.select(options.provider)::Domains
          if options.all_regions
            domains_class.all_regions
          else
            domains_class.by_region(options.region)
          end
        end

        def rows
          domains.reduce([]) do |memo, domain|
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
