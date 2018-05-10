# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      module Power
        class Off < Command
          def run
            machine = Cloudware::Machine.new
            options.name = ask('Machine name: ') if options.name.nil?
            machine.name = options.name.to_s

            options.domain = ask('Domain identifier: ') if options.domain.nil?
            machine.domain = options.domain.to_s

            Whirly.start spinner: 'dots2', status: "Powering off machine #{options.name}".bold, stop: '[OK]'.green
            machine.power_off
            Whirly.stop
          end
        end
      end
    end
  end
end
