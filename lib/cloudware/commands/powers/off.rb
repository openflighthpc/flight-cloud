# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Off < Power
        def run_power(machine)
          puts "Turning #{machine.name} off"
          machine.off
        end
      end
    end
  end
end

