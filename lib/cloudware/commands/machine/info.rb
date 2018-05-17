# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Info < Command
        def run
          table = run_whirly('Fetching machine info') do
            m = Providers.find_machine(
              options.provider,
              options.region,
              name,
              missing_error: true
            )
            Terminal::Table.new do |t|
              t.add_row ['Machine name'.bold, m.name]
              t.add_row ['Domain name'.bold, m.get_item('domain')]
              t.add_row ['Machine role'.bold, m.get_item('role')]
              t.add_row ['Pri subnet IP'.bold, m.get_item('pri_ip')]
              t.add_row ['External IP'.bold, m.get_item('ext_ip')]
              t.add_row ['Machine state'.bold, m.get_item('state')]
              t.add_row ['Machine type'.bold, m.get_item('type')]
              t.add_row ['Machine flavour'.bold, m.get_item('flavour')]
              t.add_row ['Provider'.bold, m.get_item('provider')]
              t.style = { all_separators: true }
            end
          end
          puts table
        end

        private

        attr_reader :name

        def unpack_args
          @name = args.first
        end
      end
    end
  end
end
