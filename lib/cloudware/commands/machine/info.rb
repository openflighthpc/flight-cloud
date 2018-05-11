# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Info < Command
        def run
          options.default output: 'table'
          m = Cloudware::Machine.new
          options.domain = ask('Domain name?') if options.domain.nil?
          options.name = ask('Machine name?') if options.name.nil?
          m.name = options.name.to_s
          m.domain = options.domain.to_s

          case options.output.to_s
          when 'table'
            table = Terminal::Table.new do |t|
              run_whirly('Fetching machine info') do
                t.add_row ['Machine name'.bold, m.name]
                t.add_row ['Domain name'.bold, m.get_item('domain')]
                t.add_row ['Machine role'.bold, m.get_item('role')]
                t.add_row ['Prv subnet IP'.bold, m.get_item('prv_ip')]
                t.add_row ['External IP'.bold, m.get_item('ext_ip')]
                t.add_row ['Machine state'.bold, m.get_item('state')]
                t.add_row ['Machine type'.bold, m.get_item('type')]
                t.add_row ['Machine flavour'.bold, m.get_item('flavour')]
                t.add_row ['Provider'.bold, m.get_item('provider')]
              end
              t.style = { all_separators: true }
            end
            puts table
          end
        end
      end
    end
  end
end
