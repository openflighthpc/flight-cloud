# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class List < Command
        def run
          m = Cloudware::Machine.new
          m.provider = [options.provider] unless options.provider.nil?

          # Exit if the provider is not in the config list (which verifies details ahead of time)
          if (Cloudware.config.instance_variable_get(:@providers) & m.provider).empty?
            raise "The provider #{m.provider.join(',')} is not a valid provider - unknown or missing login details"
          end

          r = []
          Whirly.start status: 'Fetching available machines'
          raise('No available machines') if m.list.nil?
          Whirly.stop
          m.list.each do |_k, v|
            r << [v[:name], v[:domain], v[:role], v[:prv_ip], v[:type], v[:state]]
          end
          table = Terminal::Table.new headings: ['Name'.bold,
                                                 'Domain'.bold,
                                                 'Role'.bold,
                                                 'Prv IP address'.bold,
                                                 'Type'.bold,
                                                 'State'.bold],
                                      rows: r
          puts table
        end
      end
    end
  end
end
