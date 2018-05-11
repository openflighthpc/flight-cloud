# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class List < Command
        def run
          d = Cloudware::Domain.new
          d.provider = [options.provider] unless options.provider.nil?
          d.region = options.region.to_s unless options.region.nil?
          d.name = options.name.to_s unless options.name.nil?

          # Exit if the provider is not in the config list (which verifies details ahead of time)
          if (Cloudware.config.instance_variable_get(:@providers) & d.provider).empty?
            raise "The provider #{d.provider.join(',')} is not a valid provider - unknown or missing login details"
          end

          r = []
          run_whirly('Fetching available domains') do
            raise('No available domains') if d.list.nil?
          end
          d.list.each do |k, v|
            r << [k, v[:network_cidr], v[:pri_subnet_cidr], v[:provider], v[:region]]
          end
          table = Terminal::Table.new headings: ['Domain name'.bold,
                                                 'Network CIDR'.bold,
                                                 'Pri Subnet CIDR'.bold,
                                                 'Provider'.bold,
                                                 'Region'.bold],
                                      rows: r
          puts table
        end
      end
    end
  end
end
