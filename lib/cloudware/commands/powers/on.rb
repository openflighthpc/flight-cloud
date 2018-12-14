# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class On < Power
        def run_power(machine)
          puts "Turning #{machine.name} on"
          machine.on
        end
      end
    end
  end
end

